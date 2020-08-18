library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- TODO: AD_trig signal

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
	signal AD_sp_state			:	std_logic	:= '0';	
	signal video_nodelay		:	integer;
	
	type data_array is array(0 to 255) of integer;	-- Integer from 0 to 65535
	signal sensor_data 			:	data_array;
	
	type swir_state is (reset, collecting, transmitting_first, transmitting, idle);
	signal state 				: swir_state	:= idle;

begin
	
	assert (sensor_clock_even = not sensor_clock_odd) 
			and not (state = idle) 
			report "sensor clock error" severity error;
			
	assert (sensor_reset_even = not sensor_reset_odd) 
			and not (state = idle)
			report "sensor reset error" severity error;
			
	assert ((Cf_select1 = '1' and Cf_select2 = '1') or (Cf_select1 = '1' and Cf_select2 = '0')) 
			and not (state = idle) 
			report "sensor cf error" severity error;
	
	process(sensor_clock_even) is
	begin
		if rising_edge(sensor_clock_even) then
			if sensor_reset_even = '1' then
				state <= reset;
				integration_counter <= integration_counter + 1;
				
				AD_sp_state <= '0';
			end if;
			
			case state is 
				when reset =>
					data_count <= 0;
					
					AD_sp_state <= '0';
					
					video_even <= 0;
					video_odd <= 0;
					
					if sensor_reset_even = '0' then
						assert integration_count >= 6 report "hold reset longer" severity error;
					
						integration_count <= integration_counter - 1;
						integration_counter <= 0;
						
						state <= collecting;
					end if;
				
				when collecting =>
					integration_count <= integration_count - 1;
					
					if integration_count = 2 then
						state <= transmitting_first;
					end if;
					
				when transmitting_first =>
					--wait until falling_edge(sensor_clock_even);
					AD_sp_state <= '1';
					
					video_even <= sensor_data(data_count);
					video_odd <= sensor_data(data_count) * (-1);
					
					data_count <= data_count + 1;
					
					state <= transmitting;
					
				when transmitting =>
					--wait until falling_edge(sensor_clock_even);
					
					AD_sp_state <= '0';
					
					video_even <= sensor_data(data_count);
					video_odd <= sensor_data(data_count) * (-1);
					
					data_count <= data_count + 1;

					if (data_count = 256) then
						state <= idle;
						data_count <= 0;
					end if;
					
				when idle =>
					video_even <= 0;
					video_odd <= 0;
					
			end case;
		end if;
	end process;
	
	process is
	begin
		if (AD_sp_state = '1') then
			wait until falling_edge(sensor_clock_even);
			AD_sp_even <= '1';
			AD_sp_odd <= '0';
		elsif (AD_sp_state = '0') then
			wait until falling_edge(sensor_clock_even);
			AD_sp_even <= '0';
			AD_sp_odd <= '1';
		end if;
	end process;
	
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
					6936, 45420, 19792);
	
	AD_trig_even <= '0';  -- for now
	AD_trig_odd <= '1';
	
end architecture;