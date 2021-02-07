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

-- swir_sensor.vhd controls signals sent to the SWIR sensor
-- When prompted by sensor_begin, will trigger imaging of one row, and will pulse sensor_done when row is finished
-- While analog data is outputed by sensor, adc_start will be sent to ADC control circuit to make it beging conversion
--	based on the fact that analog data is valid on the falling edge of the SWIR sensor clock


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity swir_sensor is
    port (
        clock_swir      	: in std_logic;
        reset_n         	: in std_logic;
        
        integration_time    : in unsigned(9 downto 0);	-- Integration time of SWIR sensor, in clock cycles of swir clock
		
		ce					: in std_logic; -- Conversion efficiency: 0 (low) or 1 (high)
		adc_trigger			: out std_logic;
		adc_start			: out std_logic;
		sensor_begin      	: in std_logic; -- Begin imaging of 1 row
		sensor_done			: out std_logic; -- Will trigger one half cycle (of swir clk) after sensor is done outputting 512 pixels
		
		-- Signals to SWIR sensor
        sensor_reset_even   : out std_logic;
		sensor_reset_odd    : out std_logic;
		Cf_select1			: out std_logic;
		Cf_select2			: out std_logic;
		AD_sp_even			: in std_logic;
		AD_sp_odd			: in std_logic;
		AD_trig_even		: in std_logic;
		AD_trig_odd			: in std_logic
    );
end entity swir_sensor;

architecture main of swir_sensor is

	signal reset_counter						: unsigned(9 downto 0);
	signal reset_n_local						: std_logic;
	signal reset_n_metastable					: std_logic;
	
	signal sensor_begin1						: std_logic;
	signal sensor_begin2						: std_logic;
	signal sensor_begin3						: std_logic;
	signal sensor_begin_local					: std_logic;
	
	signal sensor_reset							: std_logic;  -- Necessary because cannot read output
	signal counter								: unsigned(9 downto 0);
	signal adc_sp								: std_logic;


begin
	
	
	-- Get stable signals from signals which cross clock domains
	process(clock_swir) is
	begin
		
		if (rising_edge(clock_swir)) then
			reset_n_metastable	<= reset_n;
			reset_n_local 		<= reset_n_metastable;
			
			sensor_begin1		<= sensor_begin;
			sensor_begin2		<= sensor_begin1;
			sensor_begin3		<= sensor_begin2;
			
			-- Register rising edge of sensor_begin signal
			if (sensor_begin3 = '0' and sensor_begin2 = '1') then
				sensor_begin_local <= '1';
			else
				sensor_begin_local <= '0';
			end if;
		end if;
		
	end process;
	
	
	-- Hold reset signal for set period to define integration time
	process(clock_swir) is
	begin
	
		if (reset_n_local = '0') then
			reset_counter <= (others=>'0');
			sensor_reset <= '0';
			
		elsif (rising_edge(clock_swir)) then
			if (sensor_begin_local = '1') then
				reset_counter <= integration_time;
				sensor_reset <= '0';
			elsif (reset_counter /= 0) then
				reset_counter <= reset_counter - 1;
				sensor_reset <= '1';
			else
				sensor_reset <= '0';
				reset_counter <= (others=>'0');
			end if;
		end if;
		
	end process;
	
	-- Process to keep track of number of pixels outputted
	process(clock_swir) is
	begin
	
		if (reset_n_local = '0') then
			counter <= (others=>'0');
			
		elsif (rising_edge(clock_swir)) then
			if adc_sp = '1' then
				counter <= "1000000001";
			elsif counter > 1 then
				counter <= counter - 1;
			else
				counter <= (others=>'0');
			end if;
		end if;
		
	end process;
	
	
	sensor_reset_even 	<=	sensor_reset when reset_n_local = '1' else '0';  -- add reset condition to ensure it is 0 in startup state
	sensor_reset_odd 	<=	not sensor_reset;
	
	adc_sp			 	<=	'1' when AD_sp_even = '1' and AD_sp_odd = '0' else '0';
	adc_trigger 		<=	'1' when AD_trig_even = '1' and AD_trig_odd = '0' else '0';
	
	Cf_select1 			<=	'1';
	Cf_select2 			<=	'1' when ce = '0' and reset_n_local = '1' else '0';
	
	sensor_done			<=	'1' when counter = 1 else '0';
	
	adc_start			<=	not clock_swir when (counter > 2 or adc_sp = '1') else '0';

end architecture main;