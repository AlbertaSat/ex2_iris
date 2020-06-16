

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

	constant spi_output_size : integer := 48;  -- 3 * 16
	signal spi_output : std_logic_vector (0 to spi_output_size-1);

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
	
	
	-- Group SPI output into 48-bit std logic vectors for easy verification
	collect_spi_output : process(mosi, clk_sys, sclk, spi_output)
		variable i			: integer range spi_output_size downto 0 := 0;
		variable out_tmp	: std_logic_vector(0 to spi_output_size-1);	
	begin
		if rising_edge(sclk) then		
			
			out_tmp(i) := mosi;
			i := i + 1;
			
			if (i = spi_output_size) then			
				spi_output <= out_tmp;
				i := 0;
			end if;
						
		end if;
	end process collect_spi_output;
	
	
	test : process
	begin

		-- -----------------------------------
		-- Test writing then reading back data
		-- -----------------------------------
		report "Test: read after write";
		-- Reset and wait for initial transmission to end
		wait until rising_edge(clk_sys); rst_sys <= '0'; wait until rising_edge(clk_sys); rst_sys <= '1';
		wait until transmit_done = '1';
		-- Fill buffer
		wait until rising_edge(clk_sys);
		write_index <= 0; reg_in <= "010101010101010"; write_reg <= '1';  wait until rising_edge(clk_sys); write_reg <= '0';
		write_index <= 1; reg_in <= "101010101010101"; write_reg <= '1';  wait until rising_edge(clk_sys); write_reg <= '0';
		write_index <= 2; reg_in <= "110011001100110"; write_reg <= '1';  wait until rising_edge(clk_sys); write_reg <= '0';
		-- Read out buffer
		read_index <= 2; read_reg <= '1'; wait until rising_edge(clk_sys); read_reg <= '0'; wait until falling_edge(clk_sys); assert reg_out = "110011001100110" report "Test failed: read after write #1";
		read_index <= 1; read_reg <= '1'; wait until rising_edge(clk_sys); read_reg <= '0'; wait until falling_edge(clk_sys); assert reg_out = "101010101010101" report "Test failed: read after write #2";
		read_index <= 0; read_reg <= '1'; wait until rising_edge(clk_sys); read_reg <= '0'; wait until falling_edge(clk_sys); assert reg_out = "010101010101010" report "Test failed: read after write #3";
		
		-- -----------------------------------
		-- Test resetting then reading back data
		-- -----------------------------------
		report "Test: read after reset";
		-- Reset and wait for initial transmission to end
		wait until rising_edge(clk_sys); rst_sys <= '0'; wait until rising_edge(clk_sys); rst_sys <= '1';
		wait until transmit_done = '1';
		-- Read out buffer
		read_index <= 2; read_reg <= '1'; wait until rising_edge(clk_sys); read_reg <= '0'; wait until falling_edge(clk_sys); assert reg_out = "110011001100110" report "Test failed: read after reset #1";
		read_index <= 1; read_reg <= '1'; wait until rising_edge(clk_sys); read_reg <= '0'; wait until falling_edge(clk_sys); assert reg_out = "101010101010101" report "Test failed: read after reset #2";
		read_index <= 0; read_reg <= '1'; wait until rising_edge(clk_sys); read_reg <= '0'; wait until falling_edge(clk_sys); assert reg_out = "010101010101010" report "Test failed: read after reset #3";

		-- -----------------------------------
		-- Test uploading data
		-- -----------------------------------
		report "Test: upload";
		wait until rising_edge(clk_sys); transmit_array <= '1'; wait until rising_edge(clk_sys); transmit_array <= '0';
		wait until transmit_done = '1';
		wait until falling_edge(clk_sys);
		assert spi_output( 0 to 15) = "1010101010101010" report "Test failed: upload #1";
		assert spi_output(16 to 31) = "1101010101010101" report "Test failed: upload #2";
		assert spi_output(32 to 47) = "1110011001100110" report "Test failed: upload #3";

		-- -----------------------------------
		-- Test uploading on reset
		-- -----------------------------------
		report "Test: upload after reset";
		wait until rising_edge(clk_sys); rst_sys <= '0'; wait until rising_edge(clk_sys); rst_sys <= '1';
		wait until transmit_done = '1';
		wait until falling_edge(clk_sys);
		assert spi_output( 0 to 15) = "1010101010101010" report "Test failed: upload after reset #1";
		assert spi_output(16 to 31) = "1101010101010101" report "Test failed: upload after reset #2";
		assert spi_output(32 to 47) = "1110011001100110" report "Test failed: upload after reset #3";

		report "Finished running tests.";

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








