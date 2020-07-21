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

entity vnir_subsystem_tb is
end entity;


architecture tests of vnir_subsystem_tb is	   
    signal clock                : std_logic := '0';  -- Main clock
    signal reset_n              : std_logic := '0';  -- Main reset
    signal sensor_clock         : std_logic := '0';
    signal sensor_clock_locked  : std_logic;
    signal sensor_reset         : std_logic;
    signal config               : vnir_config_t;
    signal start_config         : std_logic;
    signal config_done          : std_logic;
    signal do_imaging           : std_logic := '0';
    signal imaging_done         : std_logic;
    signal num_rows             : integer;
    signal row                  : vnir_row_t;
    signal row_available        : vnir_row_type_t;
    signal spi                  : spi_t;
    signal frame_request        : std_logic;
    signal exposure_start       : std_logic;
    signal lvds                 : vnir_lvds_t := (
        clock => '0', control => '0', data => (others => '0')
    );
    
    component vnir_subsystem is
    port (
        clock               : in std_logic;
        reset_n             : in std_logic;
        sensor_clock        : in std_logic;
        sensor_clock_locked : in std_logic;
        sensor_reset        : out std_logic;
        config              : in vnir_config_t;
        start_config        : in std_logic;
        config_done         : out std_logic;
        do_imaging          : in std_logic;
        imaging_done        : out std_logic;
        num_rows            : out integer;
        row                 : out vnir_row_t;
        row_available       : out vnir_row_type_t;
        spi_out             : out spi_from_master_t;
        spi_in              : in spi_to_master_t;
        frame_request       : out std_logic;
        exposure_start      : out std_logic;
        lvds                : in vnir_lvds_t
    ); 
    end component;

begin

    debug : process (clock)
    begin
        if rising_edge(clock) then
            if do_imaging = '1' then
                report "do_imaging = 1";
            end if;
            if imaging_done = '1' then
                report "imaging_done = 1";
            end if;
            if frame_request = '1' then
                report "frame_request = 1";
            end if;
            if exposure_start = '1' then
                report "exposure_start = 1";
            end if;
            if row_available = ROW_NIR then
                report "row available = NIR";
            end if;
            if row_available = ROW_BLUE then
                report "row available = BLUE";
            end if;
            if row_available = ROW_RED then
                report "row available = RED";
            end if;
        end if;
    end process debug;

    clock_gen : process
        constant clock_period : time := 20 ns;
	begin
		wait for clock_period / 2;
		clock <= not clock;
    end process clock_gen;
    
    sensor_clock_gen : process
        constant sensor_clock_period : time := 20.83 ns;
    begin
        wait for sensor_clock_period / 2;
        sensor_clock <= not sensor_clock;
    end process sensor_clock_gen;

    lvds_clock_gen : process
        constant lvds_clock_period : time := 4.167 ns;
    begin
        wait for lvds_clock_period / 2;
        lvds.clock <= not lvds.clock;
    end process lvds_clock_gen;

    sensor : process
        type state_t is (IDLE, COLLECTING_FRAME, EMITTING_FRAME);
        variable state : state_t := IDLE;
        variable next_state : state_t := IDLE;

        constant fragments_per_row : integer := vnir_row_width / vnir_lvds_n_channels;

        variable i_bit : integer := 0;
        variable i_fragment : integer := 0;
        variable i_row : integer := 0;
        variable zero : std_logic := '1';
    begin
        wait until rising_edge(lvds.clock) or falling_edge(lvds.clock);

        case state is
        when IDLE =>
            lvds.control <= '1' when i_bit = 9 else '0';
            if exposure_start = '1' then
                next_state := COLLECTING_FRAME;
            end if;
        when COLLECTING_FRAME =>
            lvds.control <= '1' when i_bit = 9 else '0';
            if frame_request = '1' then
                next_state := EMITTING_FRAME;
            end if;
        when EMITTING_FRAME =>
            lvds.control <= '1' when i_bit = 0 else '0';
            if i_fragment = fragments_per_row - 1 and i_row = total_rows(config) - 1 then
                next_state := IDLE;
            end if;
        end case;

        lvds.data <= (others => to_unsigned(i_fragment, fragments_per_row)(vnir_pixel_bits-1-i_bit));
    
        i_bit := i_bit + 1;
        if i_bit = vnir_pixel_bits then
            i_bit := 0;
            i_fragment := i_fragment + 1;
            if i_fragment = fragments_per_row then
                i_fragment := 0;
                i_row := i_row + 1;
            end if;

            if state /= next_state then
                state := next_state;
                i_fragment := 0;
                i_row := 0;
            end if;
        end if;

    end process sensor;

	test : process
    begin
        
        -- -----------------------------------
		-- Test programming the sensor
		-- -----------------------------------
        report "Test: programming";
        wait until rising_edge(clock); reset_n <= '0'; wait until rising_edge(clock); reset_n <= '1';
        wait until rising_edge(clock);
        config.window_nir.lo  <= 0; config.window_nir.hi  <= 1;
        config.window_blue.lo <= 2; config.window_blue.hi <= 3;
        config.window_red.lo  <= 4; config.window_red.hi  <= 5;
        config.imaging_duration <= 1000;  -- 1 second
        config.fps <= 180;
        config.exposure_time <= 1;
        start_config <= '1';
        sensor_clock_locked <= '1';
        wait until rising_edge(clock);
        start_config <= '0'; 
        wait until rising_edge(clock) and config_done = '1';
        -- TODO: asserts here

        -- -----------------------------------
		-- Imaging
        -- -----------------------------------
        report "Test: imaging";
        wait until rising_edge(clock); do_imaging <= '1'; wait until rising_edge(clock); do_imaging <= '0';
        
        report "Finished running tests.";
		
		wait;
	end process test;

	u0 : vnir_subsystem port map(
        clock => clock,
        reset_n => reset_n,
        sensor_clock => sensor_clock,
        sensor_clock_locked => sensor_clock_locked,
        sensor_reset => sensor_reset,
        config => config,
        start_config => start_config,
        config_done => config_done,
        do_imaging => do_imaging,
        imaging_done => imaging_done,
        num_rows => num_rows,
        row => row,
        row_available => row_available,
        spi_out => spi.from_master,
        spi_in => spi.to_master,
        frame_request => frame_request,
        exposure_start => exposure_start,
        lvds => lvds
    );

end tests;
