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

-- Testbench to help simulate behaviour of g11508 short-wave infrared sensor
-- Since the SWIR sensor outputs the even and odd signals in two seperate data paths,
--  the "half sensor" testbench simulates a generic data path

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tb_swir_half_sensor is
	port (
		sensor_clock		: in std_logic;
        sensor_reset        : in std_logic;

		AD_sp				: out std_logic;
		AD_trig				: out std_logic;
		video				: out integer;
		
		data_sel			: in integer range 0 to 1
    );
end entity;

architecture sim of tb_swir_half_sensor is 
	signal integration_counter	:	integer		:= 0;
	signal integration_count	:	integer		:= 0;
	signal data_count			:	integer		:= 0;

	type data_array is array(0 to 512) of integer;
	signal sensor_data	 		:	data_array;
	signal sensor_data1 		:	data_array;
	signal sensor_data2 		:	data_array;
	type two_d_array is array(0 to 1) of data_array;
	signal data_choose			:	two_d_array;
	
	type swir_state is (reset, collecting, transmitting, idle);
	signal state_reg, state_next:	swir_state	:= idle;
		
	signal reset_trigger 		:	std_logic	:= '0';
	signal collecting_trigger 	:	std_logic	:= '0';
	signal transmitting_trigger :	std_logic	:= '0';
	
	signal video_d				:	integer		:= 0;
	
begin
	-- Process to assign state of main sensor FSM
	process(sensor_clock, sensor_reset) is
	begin
		if sensor_reset = '1' then
			state_reg	<=	reset;
		elsif rising_edge(sensor_clock) then
			state_reg	<= state_next;
		end if;
		
	end process;
	
	-- Main sensor FSM
	process(state_reg, sensor_reset, collecting_trigger, transmitting_trigger) is
	begin
		state_next <= state_reg;
		
		case state_reg is 
			-- Set sensor in reset if input reset is high
			when reset =>
				data_count <= 0;
				
				if sensor_reset = '0' then
					assert integration_counter >= 6 report "hold reset longer" severity error;
					
					state_next 			<=	collecting;
					integration_count 	<=	7; -- sensor kept in reset for 5+3 cycles after end of reset_even signal
				else
					integration_counter <= integration_counter + 1;
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
				if data_count = (256 - 1) then
					state_next	<=	idle;
				else
					data_count	<=	data_count + 1;
				end if;
			
			-- idle state after transmitting is done and no new reset signal
			when idle =>
				data_count	<=	0;
			
		end case;
	end process;
	
	-- Process to set AD_sp siganl
	process(sensor_clock, sensor_reset) is
	begin
	
		if sensor_reset = '1' then
			AD_sp 		<=	'0';
		-- AD_sp signal is synchronized with the falling edge of sensor clock, according to datasheet
		elsif falling_edge(sensor_clock) then
			-- If sensor is done collecting and starting to transmit, create the AD_sp pulse
			if state_reg = collecting and state_next = transmitting then
				AD_sp 	<=	'1';
			else
				AD_sp 	<=	'0';
			end if;
		end if;
		
	end process;
	
	-- Process to set video signals, which will actually be fed into ADC
	process (sensor_clock, sensor_reset) is
	begin
	
		if sensor_reset = '1' then
			video_d		<=	0;
		-- In reality, video signal is analog signal which ramps up and is guarunteed to
		-- be in stable state by falling edge of sensor clk
		-- In this testbench, the video signal is just set on the falling edge
		elsif falling_edge(sensor_clock) then
			if state_next = transmitting then
				video_d	<= 	sensor_data(data_count);
			else
				video_d	<=	0;
			end if;
		end if;
	end process;
	
	-- Set video delayed by a clock cycle cycle
	process (sensor_clock, sensor_reset) is
	begin
		if falling_edge(sensor_clock) then
			video <= video_d;
		end if;
	end process;
	
	-- Signals that continually change during a particular state to trigger FSM sensitivity list
	reset_trigger 			<= not reset_trigger when state_reg = reset and rising_edge(sensor_clock) else reset_trigger;
	collecting_trigger 		<= not collecting_trigger when state_reg = collecting and rising_edge(sensor_clock) else collecting_trigger;
	transmitting_trigger 	<= not transmitting_trigger when state_reg = transmitting and rising_edge(sensor_clock) else transmitting_trigger;
	
	-- To simulate analog data from sensor, a random array of integers from 0 to 65535 is created
	sensor_data1 <= (40404, 26634, 20215, 15590, 11625, 18113, 9442, 4075, 20163, 37863, 23453, 53226, 22379, 32353, 53728, 
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
	sensor_data2 <= (22081, 5174, 40080, 27568, 53271, 61912, 32708, 54185, 3097, 13408, 55727, 25600, 7928, 49602, 50174, 31067, 
					48639, 35924, 26061, 33895, 29281, 5891, 50249, 51333, 64566, 28933, 21314, 47843, 42792, 44846, 17796, 50429, 
					50375, 22364, 6064, 17650, 43322, 50379, 59909, 37616, 26888, 15724, 58139, 40320, 32644, 63134, 14807, 53756, 
					18465, 27210, 4109, 53899, 21475, 63306, 20704, 23494, 60622, 4446, 27686, 38483, 11957, 33379, 3390, 36147, 
					25678, 38069, 50113, 2730, 34232, 6701, 51801, 27356, 7839, 25377, 26788, 7126, 24506, 10324, 48476, 10040, 
					40829, 4892, 27475, 11845, 64849, 10934, 36787, 60147, 11395, 20173, 52498, 18903, 58362, 7378, 24174, 12193, 
					4566, 65508, 32296, 23445, 36474, 55826, 53737, 55116, 32806, 52645, 14575, 39967, 55744, 8800, 39292, 35760, 
					26408, 10109, 33864, 36811, 37273, 60412, 52942, 27697, 25238, 65008, 11299, 23309, 61040, 20785, 41546, 28553, 
					29981, 58147, 25505, 56695, 8359, 10591, 38017, 1316, 60422, 37943, 20591, 4837, 45415, 8294, 56518, 23890, 5349, 
					23725, 2641, 54711, 16436, 35957, 10541, 57133, 61793, 16342, 18810, 55635, 19128, 50520, 37524, 50920, 24929, 
					64422, 36989, 774, 63650, 53665, 60101, 20243, 1303, 36729, 5554, 34864, 26504, 20904, 45941, 18745, 63228, 60922, 
					32732, 36736, 6301, 31911, 7964, 15314, 42564, 48307, 62004, 43059, 43357, 22743, 6680, 51688, 38446, 41511, 17009, 
					2345, 60260, 64049, 2265, 34034, 26124, 35521, 32329, 54360, 4999, 3271, 44378, 5239, 45097, 50340, 35546, 46157, 
					2469, 43640, 51011, 11399, 21676, 7648, 5219, 45618, 30934, 10792, 15576, 26840, 8127, 982, 34225, 31288, 52584, 
					1431, 61371, 12485, 53474, 13619, 7154, 1472, 63948, 3011, 29298, 45118, 1046, 43433, 47185, 55249, 17841, 36795, 
					4765, 27442, 28819, 36701, 55883, 57586, 5264, 56667, 41786, 21816, 9671, 47061, 10995, 44247, 27294, 61247, 43331, 
					22447, 36201, 27463, 51495, 55607, 60557, 33819, 30030, 10902, 865, 43829, 49518, 58650, 42659, 6112, 17714, 22061, 
					56993, 20740, 15479, 60614, 20037, 38866, 15364, 36256, 45689, 62495, 60456, 41378, 57416, 12462, 65490, 57608, 42263, 
					59030, 59409, 62611, 10294, 27801, 54945, 2189, 11330, 28262, 25273, 52617, 18432, 43637, 20858, 25793, 45486, 17046, 
					43958, 23159, 16522, 63851, 57952, 56491, 59638, 8176, 54492, 43397, 65458, 22751, 7786, 46146, 45973, 58073, 5078, 
					46634, 5204, 61170, 5764, 787, 14088, 52494, 23081, 60668, 21255, 42814, 26840, 46862, 50980, 50112, 43041, 27331, 
					39672, 50650, 49772, 55821, 7753, 61849, 52546, 63161, 12120, 53915, 58135, 3533, 43397, 41335, 28211, 34245, 18188, 
					5828, 15495, 40346, 64805, 19632, 54881, 13587, 25048, 32605, 1432, 52771, 55424, 38428, 46301, 44270, 13050, 4468, 
					24543, 51152, 23125, 12079, 53073, 16807, 32668, 55191, 61914, 8636, 22216, 57456, 31896, 1445, 64971, 33334, 62994, 
					12920, 32546, 46168, 27979, 30366, 27973, 34610, 6833, 22420, 34616, 20991, 48672, 20534, 38395, 46421, 53229, 22905, 
					64862, 19996, 32894, 13195, 9152, 41639, 17032, 64151, 15905, 53048, 22553, 32406, 48727, 12375, 65321, 9840, 38436, 8673, 
					34843, 33587, 47149, 57786, 52816, 44320, 17972, 2393, 7496, 18972, 17287, 63450, 61126, 11511, 49641, 55450, 29370, 61085, 
					33282, 40201, 1615, 2029, 39448, 41810, 2002, 10034, 19384, 30544, 8519, 14321, 50241, 25896, 3295, 56987, 10119, 42814, 
					64130, 21964, 56226, 27774, 34657, 39240, 65487, 63605, 56067, 33330, 24688, 61870, 26204, 43055, 14757, 777, 7287, 38716, 
					25409, 4294, 16670, 22042, 29843, 23960, 2761, 32137, 46667, 13044, 2013, 33742, 51569, 25953, 12618, 39619, 41605, 12699, 
					62874, 63670, 12232, 13266, 47434, 18362, 18);
	data_choose <= (sensor_data1, sensor_data2);
	sensor_data <= data_choose(data_sel);
	
	-- AD_trig signal set to 0, because they are unused in the RTL
	AD_trig <= '0';
	
end architecture;