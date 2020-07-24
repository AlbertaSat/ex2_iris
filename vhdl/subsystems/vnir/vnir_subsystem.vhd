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
use work.row_collector_pkg.all;


entity vnir_subsystem is
generic (
    clocks_per_sec : integer := 50000000
);
port (
    clock               : in std_logic;
    reset_n             : in std_logic;

    sensor_clock        : in std_logic;
    sensor_clock_locked : in std_logic;
    sensor_power        : out std_logic;
    sensor_clock_enable : out std_logic;
    sensor_reset_n      : out std_logic;

    config              : in vnir_config_t;
    start_config        : in std_logic;
    config_done         : out std_logic;
    
    image_config        : in vnir_image_config_t;
    start_image_config  : in std_logic;
    image_config_done   : out std_logic;
    num_rows            : out integer;
    
    do_imaging          : in std_logic;
    imaging_done        : out std_logic;

    row                 : out vnir_row_t;
    row_available       : out vnir_row_type_t;
    
    spi_out             : out spi_from_master_t;
    spi_in              : in spi_to_master_t;
    
    frame_request       : out std_logic;
    exposure_start      : out std_logic;
    lvds                : in vnir_lvds_t
);
end entity vnir_subsystem;


architecture rtl of vnir_subsystem is

    component single_delay is
    port (
        clock   : in std_logic;
        reset_n : in std_logic;
        i       : in std_logic;
        o       : out std_logic
    );
    end component single_delay;

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
    generic (
        clocks_per_sec      : integer
    );
    port (	
        clock               : in std_logic;
        reset_n             : in std_logic;
        config              : in vnir_config_t;
        start_config        : in std_logic;
        config_done         : out std_logic;
        spi_out             : out spi_from_master_t;
        spi_in              : in spi_to_master_t;
        sensor_power        : out std_logic;
        sensor_clock_enable : out std_logic;
        sensor_reset_n      : out std_logic
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

    component frame_requester is
    generic (
        clocks_per_sec  : integer
    );
    port (
        clock               : in std_logic;
        reset_n             : in std_logic;
        config              : in vnir_config_t;
        image_config        : in vnir_image_config_t;
        start_config        : in std_logic;
        config_done         : out std_logic;
        do_imaging          : in std_logic;
        image_length        : out integer;
        sensor_clock        : in std_logic;
        frame_request       : out std_logic;
        exposure_start      : out std_logic
    );
    end component frame_requester;

    component row_collector is
    port (
        clock               : in std_logic;
        reset_n             : in std_logic;
        config              : in vnir_config_t;
        read_config         : in std_logic;
        start               : in std_logic;
        image_length        : in integer;
        done                : out std_logic;
        fragment            : in fragment_t;
        fragment_available  : in std_logic;
        row                 : out vnir_row_t;
        row_available       : out vnir_row_type_t
    );
    end component row_collector;

    signal config_reg : vnir_config_t;
    signal imaging_done_s : std_logic;
    signal start_frame_requester_config : std_logic;
    signal frame_requester_config_done : std_logic;
    signal start_sensor_config : std_logic;
    signal sensor_config_done : std_logic;
    signal start_align : std_logic;
    signal align_done : std_logic;
    signal parallel_lvds : vnir_parallel_lvds_t;
    signal parallel_lvds_available : std_logic;
    signal pixels : vnir_pixel_vector_t(vnir_lvds_n_channels-1 downto 0);
    signal pixels_available : std_logic;
    signal start_locking : std_logic;
    signal locking_done : std_logic;
    signal image_length : integer;

begin

    fsm : process
        type state_t is (RESET, PRE_CONFIG, CONFIGURING, PRE_IMAGE_CONFIG, IMAGE_CONFIGURING, IDLE, IMAGING);
        variable state : state_t;
    begin
        wait until rising_edge(clock);
        
        start_locking <= '0';
        start_frame_requester_config <= '0';
        config_done <= '0';
        image_config_done <= '0';
        pixels_available <= '0';

        if reset_n = '0' then
            state := RESET;
        end if;

        case state is
        when RESET =>
            state := PRE_CONFIG;
        when PRE_CONFIG =>
            assert start_image_config = '0';
            assert do_imaging = '0';
            if start_config = '1' then
                config_reg <= config;
                start_locking <= '1';
                state := CONFIGURING;
            end if;
        when CONFIGURING =>
            assert start_config = '0';
            assert start_image_config = '0';
            assert do_imaging = '0';
            if align_done = '1' then
                config_done <= '1';
                state := PRE_IMAGE_CONFIG;
            end if;
        when PRE_IMAGE_CONFIG =>
            assert start_config = '0';
            assert do_imaging = '0';
            if start_image_config = '1' then
                start_frame_requester_config <= '1';
                state := IMAGE_CONFIGURING;
            end if;
        when IMAGE_CONFIGURING =>
            assert start_config = '0';
            assert start_image_config = '0';
            assert do_imaging = '0';
            if frame_requester_config_done = '1' then
                image_config_done <= '1';
                state := IDLE;
            end if;
        when IDLE =>
            assert (start_config = '0' and start_image_config = '0' and do_imaging = '0') or
                   (start_config = '1' and start_image_config = '0' and do_imaging = '0') or
                   (start_config = '0' and start_image_config = '1' and do_imaging = '0') or
                   (start_config = '0' and start_image_config = '0' and do_imaging = '1');
                   
            if start_config = '1' then
                config_reg <= config;
                start_locking <= '1';
                state := CONFIGURING;
            end if;
            if start_image_config = '1' then
                start_frame_requester_config <= '1';
                state := IMAGE_CONFIGURING;
            end if;
            if do_imaging = '1' then
                -- TODO: might want to start the frame_requester here instead of it starting independently
                state := IMAGING;
            end if;
        when IMAGING =>
            assert start_config = '0';
            assert start_image_config = '0';
            assert do_imaging = '0';
            if parallel_lvds_available = '1' and parallel_lvds.control.dval = '1' then
                pixels_available <= '1';
                pixels <= parallel_lvds.data;
            end if;
            if imaging_done_s = '1' then -- TODO: might want to make sure row_collator is finished
                state := IDLE; 
            end if;
        end case;
    end process fsm;

    start_sensor_config <= locking_done;
    start_align <= sensor_config_done;

    delay_until_locked : delay_until port map (
        clock => clock,
        reset_n => reset_n,
        condition => sensor_clock_locked,
        start => start_locking,
        done => locking_done
    );

    sensor_configurer_component : sensor_configurer generic map (
        clocks_per_sec => clocks_per_sec
    ) port map (
        clock => clock,
        reset_n => reset_n,
        config => config_reg,
        start_config => start_sensor_config,
        config_done => sensor_config_done,
        spi_out => spi_out,
        spi_in => spi_in,
        sensor_power => sensor_power,
        sensor_clock_enable => sensor_clock_enable,
        sensor_reset_n => sensor_reset_n
    );
    
    frame_requester_component : frame_requester generic map (
        clocks_per_sec => clocks_per_sec
    ) port map (
        clock => clock,
        reset_n => reset_n,
        config => config_reg,
        image_config => image_config,
        start_config => start_frame_requester_config,
        config_done => frame_requester_config_done,
        image_length => image_length,
        do_imaging => do_imaging,
        sensor_clock => sensor_clock,
        frame_request => frame_request,
        exposure_start => exposure_start
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

    row_collector_component : row_collector port map (
        clock => clock,
        reset_n => reset_n,
        config => config,
        read_config => start_sensor_config,
        start => do_imaging,
        done => imaging_done_s,
        image_length => image_length,
        fragment => pixels,
        fragment_available => pixels_available,
        row => row,
        row_available => row_available
    );
    imaging_done <= imaging_done_s;

    num_rows <= image_length;

end architecture rtl;