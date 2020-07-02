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

use work.vnir_types.all;
use work.spi_types.all;


entity sensor_configurer_tb is
end entity sensor_configurer_tb;

architecture tests of sensor_configurer_tb is
    constant clock_period : time := 20 ns;

    signal clock : std_logic := '0';
    signal reset_n : std_logic := '0';
    signal config : vnir_config_t;
    signal start_config : std_logic;
    signal config_done : std_logic;
    signal spi : spi_t;

    constant spi_output_size : integer := 48;  -- 3 * 16
	signal spi_output : std_logic_vector (0 to spi_output_size-1);

    component sensor_configurer is
    port (	
        clock			: in std_logic;
        reset_n			: in std_logic;
        config          : in vnir_config_t;
        start_config    : in std_logic;
        config_done     : out std_logic;	
        spi_out			: out spi_from_master_t;
        spi_in			: in spi_to_master_t
    );
    end component sensor_configurer;
begin

    clock_gen : process
    begin
        wait for clock_period / 2;
        clock <= not clock;
    end process clock_gen;

    -- Group SPI output into 48-bit std logic vectors for easy verification
    collect_spi_output : process (spi)
        variable i			: integer := 0;
        variable out_tmp	: std_logic_vector(0 to spi_output_size-1);	
    begin
        if rising_edge(spi.from_master.clock) then		
            out_tmp(i) := spi.from_master.data;
            i := i + 1;
            if (i = spi_output_size) then			
                spi_output <= out_tmp;
                i := 0;
            end if;
        end if;
    end process collect_spi_output;

    test : process
    begin

        -- TODO: tests go here

        report "Finished running tests.";
        wait;

    end process test;

    sensor_configurer_component : sensor_configurer port map (
        clock => clock,
        reset_n => reset_n,
        config => config,
        start_config => start_config,
        config_done => config_done,
        spi_out => spi.from_master,
        spi_in => spi.to_master
    );

end architecture tests;