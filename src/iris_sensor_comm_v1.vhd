--
--
--	transmit_done can be used as an indicator on whether or not register
--	values can be written to or read from the register array
--
--	array reads and writes can be performed anytime the module isn't 
--	reprogramming the sensor
--
--	will actually need to deactivate module for 1 us after the system
-- reset signal is lifted
--
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sensor_comm_v1 is
	generic(	
		NUM_REG : integer;	
	);
	port(	
		-- Main clock and reset
		clk_sys : in std_logic;
		rst_sys : in std_logic;
		
		transmit_array : in std_logic := '0';
		transmit_done  : out std_logic := '0';
		
		-- Controls for reading reg value from array
		read_reg       : in std_logic := '0';
		read_index     : in integer;
		reg_out        : out std_logic_vector (14 downto 0);
		
		-- Controls for writing reg value to array
		write_reg      : in std_logic := '0';
		write_index    : in integer;
		reg_in         : in std_logic_vector (14 downto 0);	
	);
end entity sensor_comm_v1

architecture rtl of sensor_comm_v1 is

	-- Array for sensor register data
	type register_data_array is array (0 to NUM_REG-1) of
				     std_logic_vector (14 downto 0);
	signal reg_data : register_data_array := (
		0 => "000000000000000";
		1 => "000000000000000";                     -- default sensor register values
		-- etc
		
		-- first 7 bits are register address, last 8 bits is desired register data
	);
	
	-- Array index variable
	subtype t_array_index is integer range NUM_REG-1 downto 0;
	signal array_index    : t_array_index := '0';
	
	
	-- for FSM of module
	type   t_state is (IDLE, REPROGRAM);
	signal state : t_state := IDLE;
	
	
	component spi_controller is
	port(
		
		-- Main clock and reset
		clk_sys : in std_logic;
		rst_sys : in std_logic;	
	
		-- data to be sent via SPI
		reg_line  : in std_logic_vector (14 downto 0);
		
		-- flag data has been transmitted
		line_done : out std_logic;
	
	);
	end component;

begin

	-- Contains the main FSM which coordinates the process
	main_process : process (clk_sys,rst_sys)
	begin
		if rising_edge(clk_sys) then
			if (rst_sys = '1') then
				-- Upload default register values on reset
				state <= REPROGRAM;
				transmit_done <= '0';
			
			else
			
				case state is
					when IDLE =>
						if (transmit_array = '1') then						
							state <= REPROGRAM;
							transmit_done <= '0'
						end if;
						
						-- Read value at specified array index
						if (read_reg = '1') then
							reg_out <= reg_data(read_index);
						end if;
						
						-- Write data to specified array index
						if (write_reg = '1') then
							reg_data(write_index) <= reg_in;
						end if;
					
					
					when REPROGRAM =>
						if (array_index = NUM_REG) then
							
							-- All reg have been transmitted
							transmit_done <= '1';
							state <= IDLE;
							
						else
							-- if SPI has finished sending previous value
							if (line_done = '1') then
							
								-- transmit new reg line to SPI, increment index
								reg_line <= 1 & reg_data(array_index);
								array_index <= array_index + 1;
								
							end if;
						end if;					
					end case;		
			end if;
		end if;
	end process;
	
	
end architecture rtl;















