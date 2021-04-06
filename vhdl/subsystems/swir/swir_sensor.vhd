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

-- Signals:
--		clock_swir: 	0.78125 MHz SWIR clock
--		reset_n: 		input reset from SWIR subsystem top-level, stretched to accomadate slower SWIR clock
--
--		integration_time: number of clock clock cycles to hold sensor_reset_even for, in SWIR sensor clock cycles (actual integration time + 5)
--		
--		ce:				Conversion efficiency - 0 (low) or 1 (high)
--		adc_trigger:	Signal sent to ADC code to mirror AD_trig of SWIR sensor; unused
--		adc_start: 		Pulse sent to ADC code to tell it to begin capturing analog data
--		sensor_begin:	Pulse from SWIR top level, indicating that imaging of 1 row should begin
--		sensor_done: 	Pulse sent to SWIR top level, indicating that imaging of 1 row is done
--							Will trigger one half cycle (of swir clk) after sensor is done outputting 512 pixels
--		
--		Remaining signals are sent to or recieved from SWIR sensor (refer to SWIR sensor datasheet)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity swir_sensor is
    port (
        clock_swir      	: in std_logic;
        reset_n         	: in std_logic;
        
        integration_time    : in unsigned(9 downto 0);
		
		ce					: in std_logic;
		adc_trigger			: out std_logic;
		adc_start			: out std_logic;
		sensor_begin      	: in std_logic;
		sensor_done			: out std_logic; 
		
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
	
	signal integration_time1					: unsigned(9 downto 0);
	signal integration_time_local				: unsigned(9 downto 0);
	
	signal reset_counter						: unsigned(9 downto 0);
	signal reset_n_local						: std_logic;
	signal reset_n_metastable					: std_logic;
	
	signal sensor_begin1						: std_logic;
	signal sensor_begin2						: std_logic;
	signal sensor_begin3						: std_logic;
	signal sensor_begin_local					: std_logic;
	
	signal sensor_reset							: std_logic;  -- Necessary because cannot read output
	signal counter								: unsigned(9 downto 0);
	signal first_pixel_outputted				: std_logic;
	
	signal sensor_reset_odd_2					: std_logic;
begin
	
	
	-- Get stable signals from signals which cross clock domains (from FPGA clk domain to SWIR clk domain)
	process(clock_swir) is
	begin
		if (rising_edge(clock_swir)) then
			reset_n_metastable	<= reset_n;
			reset_n_local 		<= reset_n_metastable;
			
			sensor_begin1		<= sensor_begin;
			sensor_begin2		<= sensor_begin1;
			sensor_begin3		<= sensor_begin2;
			
			-- Note: start of integration occurs at lest 4 clock cycles after integration time is registered
			integration_time1(0)	  <= integration_time(0);
			integration_time_local(0) <= integration_time1(0);
			integration_time1(1)	  <= integration_time(1);
			integration_time_local(1) <= integration_time1(1);
			integration_time1(2)	  <= integration_time(2);
			integration_time_local(2) <= integration_time1(2);
			integration_time1(3)	  <= integration_time(3);
			integration_time_local(3) <= integration_time1(3);
			integration_time1(4)	  <= integration_time(4);
			integration_time_local(4) <= integration_time1(4);
			integration_time1(5)	  <= integration_time(5);
			integration_time_local(5) <= integration_time1(5);
			integration_time1(6)	  <= integration_time(6);
			integration_time_local(6) <= integration_time1(6);
			integration_time1(7)	  <= integration_time(7);
			integration_time_local(7) <= integration_time1(7);
			integration_time1(8)	  <= integration_time(8);
			integration_time_local(8) <= integration_time1(8);
			integration_time1(9)	  <= integration_time(9);
			integration_time_local(9) <= integration_time1(9);
			
			-- Register rising edge of sensor_begin signal
			if (sensor_begin3 = '0' and sensor_begin2 = '1') then
				sensor_begin_local <= '1';
			else
				sensor_begin_local <= '0';
			end if;
		end if;
	end process;
	
	-- Hold reset signal for set period to define integration time
	process(clock_swir, reset_n_local) is
	begin
		if (reset_n_local = '0') then
			reset_counter <= (others=>'0');
			sensor_reset <= '0';
		
		-- Set reset signal according to reset_counter which indicates how long it should be held for
		elsif (rising_edge(clock_swir)) then
			if (sensor_begin_local = '1') then
				reset_counter <= integration_time_local;
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
	
	-- Process to keep track of number of pixels outputted (512 pixels total)
	process(clock_swir, reset_n_local) is
	begin
		if (reset_n_local = '0') then
			counter <= (others=>'0');
			
		elsif (rising_edge(clock_swir)) then
			if first_pixel_outputted = '1' then  -- If pixel outputting has begun
				counter <= "1000000000";  -- =512
			elsif counter > 1 then  -- Decrement counter
				counter <= counter - 1;
			else
				counter <= (others=>'0');
			end if;
		end if;
	end process;
	
	
	-- Delay sensor_reset_even by 1 clock cycle
	-- Since odd pixel will be outputed first, 
	--   and sensor even pixel is 1/2 clock_swir, shifted by 180 deg.
	--   this corresponds to 1 clock cycle shift of sensor_reset_even
	process(clock_swir, reset_n_local) is
	begin
		if (reset_n_local = '0') then
			sensor_reset_even <= '0';
			
		elsif (rising_edge(clock_swir)) then
			if sensor_reset_odd_2 = '1' then
				sensor_reset_even <= '1';
			else
				sensor_reset_even <= '0';
			end if;
		end if;
	end process;
	
	-- First pixel outputted after falling edge of ad_sp_odd, while ad_sp_even is still high, since it is delayed by a clock cycle
	first_pixel_outputted <= '1' when AD_sp_odd = '0' and AD_sp_even = '1' else '0';
	
	sensor_reset_odd_2 	<=	sensor_reset when reset_n_local = '1' else '0';  -- add reset condition to ensure it is 0 in startup state
	sensor_reset_odd	<=	sensor_reset_odd_2;  -- Due to VHDL not being able to read outputs
	
	-- Register signals from SWIR sensor
	adc_trigger 		<=	'1' when AD_trig_even = '1' or AD_trig_odd = '1' else '0';  -- UNUSED
	
	-- Set conversion efficiency
	Cf_select1 			<=	'1';
	Cf_select2 			<=	'1' when ce = '0' else '0';
	
	-- Indicates when 512 pixels have been outputted
	sensor_done			<=	'1' when counter = 1 else '0';
	
	-- Indicates ADC to do a conversion when the sensor indicates it has begun outputting, and every SWIR sensor clock cycle after that until all pixels outputted
	adc_start			<=	clock_swir when (counter > 1 or first_pixel_outputted = '1') else '0';

end architecture main;