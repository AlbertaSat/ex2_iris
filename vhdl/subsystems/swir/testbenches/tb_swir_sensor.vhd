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

-- Testbench to simulate behaviour of g11508 short-wave infrared sensor

-- TODO: AD_trig signal
-- 		Assert statement for clock not working

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_swir_sensor is
	port (
		sensor_clock_even   : in std_logic;
		sensor_clock_odd    : in std_logic;
        sensor_reset_even   : in std_logic;
		sensor_reset_odd    : in std_logic;
		Cf_select1			: in std_logic;
		Cf_select2			: in std_logic;
		
		AD_sp_even			: out std_logic;
		AD_sp_odd			: out std_logic;
		AD_trig_even		: out std_logic;
		AD_trig_odd			: out std_logic;
		
		video_even			: out integer;
		video_odd			: out integer
    );
end entity;

architecture sim of tb_swir_sensor is 
	signal integration_counter	:	integer		:= 0;
	signal integration_count	:	integer		:= 0;
	signal data_count			:	integer		:= 0;

	type data_array is array(0 to 512) of integer;
	signal sensor_data 			:	data_array;
	
	type swir_state is (reset, collecting, transmitting, idle);
	signal state_reg, state_next:	swir_state	:= idle;
		
	signal reset_trigger 		:	std_logic	:= '0';
	signal collecting_trigger 	:	std_logic	:= '0';
	signal transmitting_trigger :	std_logic	:= '0';
	
begin
	
	-- Check that even and odd signals are aligned
	assert (sensor_clock_even = not sensor_clock_odd) 
			and not (state_reg = idle) 
			report "sensor clock error" severity error;
		
	assert (sensor_reset_even = not sensor_reset_odd) 
		and not (state_reg = idle)
		report "sensor reset error" severity error;
	
	-- Check that cf signal are of acceptable values
	assert ((Cf_select1 = '1' and Cf_select2 = '1') or (Cf_select1 = '1' and Cf_select2 = '0')) 
		and not (state_reg = idle) 
		report "sensor cf error" severity error;
		
	
	-- Process to assign state of main sensor FSM
	process(sensor_clock_even, sensor_reset_even) is
	begin
	
		if sensor_reset_even = '1' then
			state_reg	<=	reset;
		elsif rising_edge(sensor_clock_even) then
			state_reg	<= state_next;
		end if;
		
	end process;
	
	-- Main sensor Mealy FSM
	process(state_reg, reset_trigger, collecting_trigger, transmitting_trigger) is
	begin
		state_next <= state_reg;
		
		case state_reg is 
			-- Set sensor in reset if input reset is high, and keep track of how many clock cycles it is high for
			when reset =>
				data_count <= 0;
				
				if sensor_reset_even = '0' then
					assert integration_count >= 6 report "hold reset longer" severity error;
					
					state_next 			<=	collecting;
					integration_count 	<=	integration_counter - 1;
				else 
					integration_counter <=	integration_counter + 1;
				end if;
			
			-- Set sensor in collecting mode (integration) for amount of cycles specified by reset signal
			when collecting =>
				integration_counter <= 	0;
				
				if integration_count = 0 then
					state_next 			<=	transmitting;
				else
					integration_count	<=	integration_count - 1;
				end if;
				
			-- Set sensor to transmit data state for 256 cycles (1 cycle per pixel)
			when transmitting =>
				if data_count = (512 - 1) then
					state_next			<=	idle;
				else
					data_count			<=	data_count + 1;
				end if;
			
			-- idle state after transmitting is done and no new reset signal
			when idle =>
				data_count			<=	0;
				
		end case;
	end process;
	
	-- Process to set AD_sp siganl
	process(sensor_clock_even, sensor_reset_even) is
	begin
	
		if sensor_reset_even = '1' then
			AD_sp_even 		<=	'0';
			AD_sp_odd		<=	'1';
		-- AD_sp signal is synchronized with the falling edge of sensor clock, according to datasheet
		elsif falling_edge(sensor_clock_even) then
			-- If sensor is done collecting and starting to transmit, create the AD_sp pulse
			if state_reg = collecting and state_next = transmitting then
				AD_sp_even 	<=	'1';
				AD_sp_odd 	<=	'0';
			else
				AD_sp_even 	<=	'0';
				AD_sp_odd 	<=	'1';
			end if;
		end if;
		
	end process;
	
	-- Process to set video signals, which will actually be fed into ADC
	process (sensor_clock_even, sensor_reset_even) is
	begin
	
		if sensor_reset_even = '1' then
			video_even		<=	0;
			video_odd		<=	0;
		-- In reality, video signal is analog signal which ramps up and is guarunteed to
		-- be in stable state by falling edge of sensor clk
		-- In this testbench, the video signal is just set on the falling edge
		elsif falling_edge(sensor_clock_even) then
			if state_next = transmitting then
				video_even	<= 	sensor_data(data_count);
				video_odd	<= 	sensor_data(data_count) * (-1);
			else
				video_even	<=	0;
				video_odd	<=	0;
			end if;
		end if;
		
	end process;
	
	-- Signals that continually change during a particular state to trigger FSM sensitivity list
	reset_trigger 			<= not reset_trigger when state_reg = reset and rising_edge(sensor_clock_even) else reset_trigger;
	collecting_trigger 		<= not collecting_trigger when state_reg = collecting and rising_edge(sensor_clock_even) else collecting_trigger;
	transmitting_trigger 	<= not transmitting_trigger when state_reg = transmitting and rising_edge(sensor_clock_even) else transmitting_trigger;
	
	
	-- To simulate analog data from sensor, a random array of integers from 0 to 65535 is created
	sensor_data <= (40404, 26634, 20215, 15590, 11625, 18113, 9442, 4075, 20163, 37863, 23453, 53226, 22379, 32353, 53728, 
					23674, 55884, 52598, 14179, 48069, 49047, 33908, 59860, 55072, 45777, 18990, 24934, 20191, 16476, 39371, 
					2144, 31574, 3222, 43408, 5225, 17360, 3128, 54089, 52660, 3504, 22150, 52764, 8397, 47827, 27159, 60565, 
					49040, 37901, 57416, 63089, 16219, 41771, 14024, 26135, 12345, 49901, 3091, 60684, 13145, 10471, 48854, 
					45150, 26610, 30202, 23747, 10200, 22354, 1926, 4026, 64522, 20468, 34559, 3276, 46628, 1891, 7793, 57403, 
					29027, 36489, 16056, 31198, 58257, 3656, 39985, 24104, 61101, 21963, 6913, 39865, 48461, 30553, 4582, 30775, 
					5332, 65159, 39208, 61725, 28218, 47584, 10555, 35423, 2620, 24851, 23508, 14893, 52275, 50874, 3842, 28857, 
					51029, 29058, 47414, 62713, 10133, 24354, 25758, 42920, 63300, 41295, 2612, 14011, 7357, 23675, 36918, 9463, 
					64006, 18138, 17668, 10798, 37932, 63964, 22651, 9741, 25616, 58905, 831, 46305, 20682, 17604, 2342, 50317, 
					58300, 29422, 31831, 57079, 47052, 62771, 42186, 58001, 27049, 48415, 62737, 44118, 15530, 14478, 63954, 34068, 
					13928, 16501, 59507, 39700, 8732, 18047, 53057, 40460, 11945, 51619, 26372, 14855, 62770, 14826, 51633, 6053, 
					54353, 44403, 63706, 3709, 54163, 44413, 20228, 49878, 3795, 35447, 18171, 30340, 15207, 3363, 31218, 61203, 
					4975, 12954, 6147, 44528, 8910, 36885, 57552, 31356, 41002, 55481, 38283, 58715, 62652, 35919, 10914, 18383, 
					48382, 38050, 15256, 26833, 11128, 7380, 60531, 13663, 47230, 5343, 11393, 620, 60657, 15991, 25422, 33291, 
					6210, 23597, 23903, 58141, 19334, 15279, 17350, 28134, 29312, 41969, 54408, 59644, 36289, 7320, 4414, 60087, 
					63691, 59556, 14525, 19151, 24409, 55085, 11031, 10026, 5804, 1381, 39201, 16332, 21311, 62461, 26132, 58967, 
					6936, 45420, 19792, 57079, 47052, 62771, 42186, 58001, 27049, 48415, 62737, 44118, 15530, 14478, 63954, 34068,
					40404, 26634, 20215, 15590, 11625, 18113, 9442, 4075, 20163, 37863, 23453, 53226, 22379, 32353, 53728, 
					23674, 55884, 52598, 14179, 48069, 49047, 33908, 59860, 55072, 45777, 18990, 24934, 20191, 16476, 39371, 
					2144, 31574, 3222, 43408, 5225, 17360, 3128, 54089, 52660, 3504, 22150, 52764, 8397, 47827, 27159, 60565, 
					49040, 37901, 57416, 63089, 16219, 41771, 14024, 26135, 12345, 49901, 3091, 60684, 13145, 10471, 48854, 
					45150, 26610, 30202, 23747, 10200, 22354, 1926, 4026, 64522, 20468, 34559, 3276, 46628, 1891, 7793, 57403, 
					29027, 36489, 16056, 31198, 58257, 3656, 39985, 24104, 61101, 21963, 6913, 39865, 48461, 30553, 4582, 30775, 
					5332, 65159, 39208, 61725, 28218, 47584, 10555, 35423, 2620, 24851, 23508, 14893, 52275, 50874, 3842, 28857, 
					51029, 29058, 47414, 62713, 10133, 24354, 25758, 42920, 63300, 41295, 2612, 14011, 7357, 23675, 36918, 9463, 
					64006, 18138, 17668, 10798, 37932, 63964, 22651, 9741, 25616, 58905, 831, 46305, 20682, 17604, 2342, 50317, 
					58300, 29422, 31831, 57079, 47052, 62771, 42186, 58001, 27049, 48415, 62737, 44118, 15530, 14478, 63954, 34068, 
					13928, 16501, 59507, 39700, 8732, 18047, 53057, 40460, 11945, 51619, 26372, 14855, 62770, 14826, 51633, 6053, 
					54353, 44403, 63706, 3709, 54163, 44413, 20228, 49878, 3795, 35447, 18171, 30340, 15207, 3363, 31218, 61203, 
					4975, 12954, 6147, 44528, 8910, 36885, 57552, 31356, 41002, 55481, 38283, 58715, 62652, 35919, 10914, 18383, 
					48382, 38050, 15256, 26833, 11128, 7380, 60531, 13663, 47230, 5343, 11393, 620, 60657, 15991, 25422, 33291,
					54353, 44403, 63706, 3709, 54163, 44413, 20228, 49878, 3795, 35447, 18171, 30340, 15207, 3363, 31218, 64006,
					18138, 17668, 10798, 37932, 63964, 22651, 9741);
	
	-- AD_trig signal set to 0 for now
	AD_trig_even <= '0';
	AD_trig_odd <= '1';
	
end architecture;