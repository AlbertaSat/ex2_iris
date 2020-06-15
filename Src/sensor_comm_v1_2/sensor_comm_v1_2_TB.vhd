

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity sensor_comm_v1_2_TB is

end entity;

architecture rtl of sensor_comm_v1_2_TB is

	constant clockPeriod	: time := 20 ns;

	signal clk_sys			: std_logic := '0';
	signal rst_sys			: std_logic := '1';
	
	signal transmit_array	: std_logic := '0';
	signal transmit_done	: std_logic := '0';
	
	signal read_reg			: std_logic := '0';
	signal read_index		: integer := 0;
	signal reg_out			: std_logic_vector (14 downto 0);
	
	signal write_reg		: std_logic := '0';
	signal write_index		: integer := 0;
	signal reg_in			: std_logic_vector (14 downto 0);
	
	signal sclk				: std_logic;
	signal miso				: std_logic;
	--signal ss_n				: std_logic_vector (0 downto 0);
	signal mosi				: std_logic;
	signal ss				: std_logic;


	signal sentWord			: std_logic_vector (0 to 15);

	component sensor_comm_v1_2 is
		generic(	
			NUM_REG : integer	
		);
		port(	
			-- Main clock and reset
			clk_sys 		: in std_logic;
			rst_sys 		: in std_logic;
			
			-- Controls for uploading code to sensor
			transmit_array 	: in std_logic := '0';    
			transmit_done  	: out std_logic := '0';    
			
			-- Controls for reading reg value from array
			read_reg       	: in std_logic := '0';
			read_index     	: in integer;
			reg_out        	: out std_logic_vector (14 downto 0);
			
			-- Controls for writing reg value to array
			write_reg    	: in std_logic := '0';
			write_index    	: in integer;
			reg_in         	: in std_logic_vector (14 downto 0);	
			
			-- SPI Data transfer signals
			sclk			: out std_logic;
			miso			: in std_logic;
			--ss_n			: out std_logic_vector(0 downto 0);
			ss				: out std_logic;
			mosi			: out std_logic
			
		);
	end component;

begin

	-- Generate main clock signal
	clockGen : process
	begin
		wait for clockPeriod / 2;
		clk_sys <= not clk_sys;
	end process clockGen;
	
	
	-- Group SPI output into 16-bit std logic vectors for easy verification
	outputWords : process(mosi, clk_sys, sclk, sentWord)	
		subtype t_count is integer range 16 downto 0;
		variable count	: t_count := 0;                    
		variable tempWord : std_logic_vector(0 to 15);	
	begin
		if rising_edge(sclk) then		
			
			tempWord(count) := mosi;
			--tempWord := tempWord(15 downto 1) & mosi;	
			count := count + 1;
			
			if (count = 16) then			
				sentWord <= tempWord;
				count := 0;
			end if;
						
		end if;
	end process outputWords;
	
	
	test : process
	begin
	
		wait for 20 ns;	
		
		
		-- Test ability to read data stored in register array
		-- read_index <= 0;
		-- read_reg <= '1';
		-- wait for 20 ns;		
		-- read_reg <= '0';
		-- wait for 20 ns;
		
		-- read_index <= 1;
		-- read_reg <= '1';
		-- wait for 20 ns;
		-- read_reg <= '0';
		-- wait for 20 ns;
		
		-- Test ability to write data stored in register array		
		-- write_index <= 0;
		-- reg_in <= "111111111111111";
		-- write_reg <= '1';
		-- wait for 20 ns;
		-- write_reg <= '0';
		
		-- read_index <= 0;
		-- read_reg <= '1';
		-- wait for 20 ns;
		-- read_reg <= '0';
		-- wait for 20 ns;
		
		-- Test ability to transmit register data via SPI
		transmit_array <= '1';
		wait for 20 ns;
		transmit_array <= '0';
		wait until transmit_done = '1';
		wait for 2 ps;                     -- Requires short delay here, not sure why, might be so sim updates signals?
		-- w/o delay, first interal array write doesn't work properly
		
		-- Test ability to modify internal register array between transfers
		write_index <= 0;
		reg_in <= "111011101100000";
		write_reg <= '1';
		wait for 20 ns;
		write_index <= 1;
		reg_in <= "100001000001010";
		write_reg <= '1';
		wait for 20 ns;
		write_index <= 2;
		reg_in <= "100011001000000";
		write_reg <= '1';
		wait for 20 ns;
		write_reg <= '0';
		wait for 20 ns;         -- to update value of write_reg in sim
		
		-- Second data transfer
		transmit_array <= '1';
		wait for 20 ns;
		transmit_array <= '0';
		wait until transmit_done = '1';
		
		
		wait;
	
	end process test;
	
	
	-- Instantiate the sensor register control module
	dut : sensor_comm_v1_2
		generic map(
			NUM_REG		=> 3
		)
		port map(
			clk_sys			=> clk_sys,
			rst_sys			=> rst_sys,
			transmit_array	=> transmit_array,
			transmit_done	=> transmit_done,
			read_reg		=> read_reg,
			read_index		=> read_index,
			reg_out			=> reg_out,
			write_reg		=> write_reg,
			write_index		=> write_index,
			reg_in			=> reg_in,
			sclk			=> sclk,
			miso			=> miso,
			--ss_n			=> ss_n,
			ss				=> ss,
			mosi			=> mosi
		);

end rtl;








