----------------------------------------------------------------
-- Copyright 2020 University of Alberta

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.spi_types.all;
use work.vnir_types.all;


entity vnir_subsystem is
port (
    clock               : in std_logic;
    reset_n             : in std_logic;

    sensor_clock        : in std_logic;
    sensor_clock_locked : in std_logic;
    sensor_reset        : out std_logic;

    config              : in vnir_config_t;
    config_done         : out std_logic;
    
    do_imaging          : in std_logic;

    num_rows            : out integer;
    rows                : out vnir_rows_t;
    rows_available      : out std_logic;
    
    spi_out             : out spi_from_master_t;
    spi_in              : in spi_to_master_t;
    
    frame_request       : out std_logic;
    lvds                : in vnir_lvds_t
);
end entity vnir_subsystem;


architecture rtl of vnir_subsystem is

    component delay_until is
    port (
        clock           : in std_logic;
        reset_n         : in std_logic;
        condition       : in std_logic;
        start           : in std_logic;
        done            : out std_logic
    );
    end component delay_until;

    component sensor_configurer is
    port (	
        clock           : in std_logic;
        reset_n         : in std_logic;
        config          : in vnir_config_t;
        start_config    : in std_logic;
        config_done     : out std_logic;	
        spi_out         : out spi_from_master_t;
        spi_in          : in spi_to_master_t;
        sensor_reset    : out std_logic
    );
    end component sensor_configurer;

    component lvds_decoder is
    port (
        clock           : in std_logic;
        reset_n         : in std_logic;
        start_align     : in std_logic;
        align_done      : out std_logic;
        lvds_in         : in vnir_lvds_t;
        parallel_out    : out vnir_parallel_lvds_t;
        data_available  : out std_logic
    );
    end component lvds_decoder;

    component image_requester is
    generic (
        clocks_per_sec  : integer
    );
    port (
        clock           : in std_logic;
        reset_n         : in std_logic;
        config          : in vnir_config_t;
        read_config     : in std_logic;
        num_frames      : out integer;
        do_imaging      : in std_logic;
        imaging_done    : out std_logic;
        sensor_clock    : in std_logic;
        frame_request   : out std_logic
    );
    end component image_requester;

    component row_collator is
    port (
        clock            : in std_logic;
        reset_n          : in std_logic;
        config           : in vnir_config_t;
        read_config      : in std_logic;
        pixels           : in vnir_pixel_vector_t(vnir_lvds_data_width-1 downto 0);
        pixels_available : in std_logic;
        rows             : out vnir_rows_t;
        rows_available   : out std_logic
    );
    end component row_collator;

    constant clocks_per_sec : integer := 50000000;  -- TODO: set this to its actual value

    signal config_reg : vnir_config_t;
    signal imaging_done : std_logic;
    signal start_sensor_config : std_logic;
    signal sensor_config_done : std_logic;
    signal start_align : std_logic;
    signal align_done : std_logic;
    signal parallel_lvds : vnir_parallel_lvds_t;
    signal parallel_lvds_available : std_logic;
    signal pixels : vnir_pixel_vector_t(vnir_lvds_data_width-1 downto 0);
    signal pixels_available : std_logic;
    signal start_locking : std_logic;
    signal locking_done : std_logic;

begin

    sm : process
        type state_t is (RESET, IDLE, CONFIGURING, IMAGING);
        variable state : state_t;
    begin
        wait until rising_edge(clock);
        
        start_locking <= '0';
        config_done <= '0';
        pixels_available <= '0';

        if reset_n = '0' then
            state := RESET;
        end if;

        case state is
        when RESET =>
            state := IDLE;
        when IDLE =>
            if config.start_config = '1' then
                config_reg <= config;
                start_locking <= '1';
                state := CONFIGURING;
            elsif do_imaging = '1' then
                -- TODO: might want to start the image_requester here instead of it starting independently
                state := IMAGING;
            end if;
        when CONFIGURING =>
            if align_done = '1' then
                config_done <= '1';
                state := IDLE;
            end if;
        when IMAGING =>
            if parallel_lvds_available = '1' and parallel_lvds.control.dval = '1' then
                pixels_available <= '1';
                pixels <= parallel_lvds.data;
            end if;
            if imaging_done = '1' then -- TODO: might want to make sure row_collator is finished
                state := IDLE; 
            end if;
        end case;
    end process sm;

    start_sensor_config <= locking_done;
    start_align <= sensor_config_done;

    delay_until_locked : delay_until port map (
        clock => clock,
        reset_n => reset_n,
        condition => sensor_clock_locked,
        start => start_locking,
        done => locking_done
    );

    sensor_configurer_component : sensor_configurer port map (
        clock => clock,
        reset_n => reset_n,
        config => config_reg,
        start_config => start_sensor_config,
        config_done => sensor_config_done,
        spi_out => spi_out,
        spi_in => spi_in,
        sensor_reset => sensor_reset
    );
    
    image_requester_component : image_requester generic map (
        clocks_per_sec => clocks_per_sec
    ) port map (
        clock => clock,
        reset_n => reset_n,
        config => config_reg,
        read_config => start_sensor_config,
        num_frames => num_rows,
        do_imaging => do_imaging,  -- TODO: might want to use a registered input here
        imaging_done => imaging_done,
        sensor_clock => sensor_clock,
        frame_request => frame_request
    );

    lvds_decoder_component : lvds_decoder port map (
        clock => clock,
        reset_n => reset_n,
        start_align => start_align,
        align_done => align_done,
        lvds_in => lvds,
        parallel_out => parallel_lvds,
        data_available => parallel_lvds_available
    );

    row_collator_component : row_collator port map (
        clock => clock,
        reset_n => reset_n,
        config => config,
        read_config => start_sensor_config,
        pixels => pixels,
        pixels_available => pixels_available,
        rows => rows,
        rows_available => rows_available
    );

    debug : process (clock) is
        variable chunk : vnir_pixel_t;
    begin
        if rising_edge(clock) then
            if pixels_available = '1' then
                chunk := pixels(0);
                report "Recieved chunk: " & integer'image(to_integer(chunk));
            end if;
        end if;
    end process debug;

end architecture rtl;