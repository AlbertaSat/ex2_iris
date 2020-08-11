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

-- TODO: Voltage signal
-- Bound integers

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity swir_sensor is
    port (
        clock_swir      	: in std_logic;
        reset_n         	: in std_logic;
        
        integration_time    : in integer;	-- Integration time of SWIR sensor, in clock cycles of swir clock
		
		ce					: in std_logic; -- Conversion efficiency: 0 (low) or 1 (high)
		do_imaging      	: in std_logic;
		adc_trigger			: out std_logic;
		adc_start			: out std_logic;
	
		-- Signals to SWIR sensor
        sensor_clock_even   : out std_logic;
		sensor_clock_odd    : out std_logic;
        sensor_reset_even   : out std_logic;
		sensor_reset_odd    : out std_logic;
		Cf_select1			: out std_logic;
		Cf_select1			: out std_logic;
		AD_sp_even			: in std_logic;
		AD_sp_odd			: in std_logic;
		AD_trig_even		: in std_logic;
		AD_trig_odd			: in std_logic
    );
end entity swir_sensor;

architecture main of swir_sensor is

	signal reset_counter						: integer;
	signal reset_n_local						: std_logic;
	signal reset_n_metastable					: std_logic;
	
	signal do_imaging_metastable				: std_logic;
	signal do_imaging_local						: std_logic;
	
	

begin
	
	
	-- Get stable signals from signals which cross clock domains
	process(clock_swir) is
	begin
		
		if (rising_edge(clock_swir)) then
			reset_n_metastable <= reset_n;
			reset_n_local <= reset_n_metastable;
			
			do_imaging_metastable <= do_imaging;
			do_imaging_local <= do_imaging_metastable;
		end if;
		
	end process;
	
	
	-- Hold reset signal for set period to define integration time
	process(clock_swir) is
	begin
	
		if (reset_n_local = '0' or do_imaging_local = '1') then
			reset_counter <= integration_time;
			
		elsif (rising_edge(clock_swir)) then
			if (swir_reset /= 0) then
				reset_counter <= reset_counter - 1;
				sensor_reset_even <= '1';
			else
				sensor_reset_even <= '0';
				reset_counter <= integration_time;
			end if;
		end if;
		
	end process;
	

	sensor_clock_even <= clock_swir;
	sensor_clock_odd <= not clock_swir;
	
	sensor_reset_odd <= not sensor_reset_even;
	
	adc_start <= '1' when AD_sp_even = '1' and AD_sp_odd = '0' else '0';
	adc_trigger <= '1' when AD_trig_even = '1' and AD_trig_odd = '0' else '0';
	
	Cf_select1 <= '1';
	Cf_select1 <= '1' when ce = 0 and reset_n_local = '1' else '0';

end architecture main;