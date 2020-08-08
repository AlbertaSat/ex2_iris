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

library std;
use std.env.stop;

use work.spi_types.all;
use work.vnir_base.all;
use work.frame_requester_pkg.all;

use work.vnir.FRAGMENT_WIDTH;

entity frame_requester_tb is
end entity;


architecture tests of frame_requester_tb is	    
    signal clock            : std_logic := '0';  -- Main clock
    signal reset_n          : std_logic := '1';  -- Main reset
    signal config           : config_t;
    signal start_config     : std_logic := '0';
    signal config_done      : std_logic;
    signal do_imaging       : std_logic;
    signal imaging_done     : std_logic;
    signal sensor_clock     : std_logic := '0';
    signal frame_request    : std_logic;
    signal exposure_start   : std_logic;
    
    component frame_requester is
    generic (
        FRAGMENT_WIDTH      : integer := FRAGMENT_WIDTH;
        clocks_per_sec      : integer
    );
    port (
        clock               : in std_logic;
        reset_n             : in std_logic;
        config              : in config_t;
        start_config        : in std_logic;
        config_done         : out std_logic;
        do_imaging          : in std_logic;
        imaging_done        : out std_logic;
        sensor_clock        : in std_logic;
        frame_request       : out std_logic;
        exposure_start      : out std_logic
    ); 
	end component frame_requester;

begin

    debug : process (frame_request, do_imaging)
    begin
        if rising_edge(do_imaging) then
            report "Detected do_imaging rising edge";
        end if;
        if rising_edge(frame_request) then
            report "Detected frame_request rising edge";
        end if;
    end process debug;

    clock_gen : process
        constant PERIOD : time := 20 ns;
	begin
		wait for PERIOD / 2;
		clock <= not clock;
    end process clock_gen;
    
    sensor_clock_gen : process
        constant PERIOD : time := 0.02083 us;
    begin
        wait for PERIOD / 2;
        sensor_clock <= not sensor_clock;
    end process sensor_clock_gen;
    
	test : process
    begin
        
        reset_n <= '0'; wait until rising_edge(clock); reset_n <= '1';
        
        config <= (num_frames => 5, fps => 100, exposure_time => 5);
        start_config <= '1'; wait until rising_edge(clock); start_config <= '0';
        wait until rising_edge(clock) and config_done = '1';

        do_imaging <= '1'; wait until rising_edge(clock); do_imaging <= '0';
        
        wait until rising_edge(clock) and imaging_done = '1';
        stop;

	end process test;

    frame_requester_component : frame_requester generic map (
        clocks_per_sec => 50000000
    ) port map(
        clock => clock,
        reset_n => reset_n,
        config => config,
        start_config => start_config,
        config_done => config_done,
        do_imaging => do_imaging,
        imaging_done => imaging_done,
        sensor_clock => sensor_clock,
        frame_request => frame_request,
        exposure_start => exposure_start
    );

end tests;
