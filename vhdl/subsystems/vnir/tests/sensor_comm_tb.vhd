----------------------------------------------------------------
--	
--	 Copyright (C) 2015  University of Alberta
--	
--	 This program is free software; you can redistribute it and/or
--	 modify it under the terms of the GNU General Public License
--	 as published by the Free Software Foundation; either version 2
--	 of the License, or (at your option) any later version.
--	
--	 This program is distributed in the hope that it will be useful,
--	 but WITHOUT ANY WARRANTY; without even the implied warranty of
--	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--	 GNU General Public License for more details.
--	
--	
-- @file sensor_comm_tb.vhd
-- @authors Alexander Epp, Campbell Rea
-- @date 2020-06-16
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity sensor_comm_tb is
end entity;

architecture tests of sensor_comm_tb is

	constant clock_period	: time := 20 ns;

	signal clock			: std_logic := '0';
	signal reset_n			: std_logic := '1';
	signal transmit_cmd		: std_logic := '0';
	signal is_transmitting	: std_logic := '1';
	signal read_cmd			: std_logic := '0';
	signal read_address		: integer := 0;
	signal read_out			: std_logic_vector (14 downto 0);
	signal write_cmd		: std_logic := '0';
	signal write_address	: integer := 0;
	signal write_in			: std_logic_vector (14 downto 0);
	signal sclk				: std_logic;
	signal miso				: std_logic;
	signal mosi				: std_logic;
	signal ss				: std_logic;

	constant spi_output_size : integer := 48;  -- 3 * 16
	signal spi_output : std_logic_vector (0 to spi_output_size-1);

	component sensor_comm is
		generic(	
			NUM_REG : integer	
		);
		port(
			clock 			: in std_logic;
			reset_n 		: in std_logic;
			transmit_cmd 	: in std_logic;    
			is_transmitting	: out std_logic;    
			read_cmd		: in std_logic;
			read_address	: in integer;
			read_out       	: out std_logic_vector (14 downto 0);
			write_cmd    	: in std_logic;
			write_address	: in integer;
			write_in       	: in std_logic_vector (14 downto 0);	
			sclk			: out std_logic;
			miso			: in std_logic;
			ss				: out std_logic;
			mosi			: out std_logic
		);
	end component;

begin

	-- Generate main clock signal
	clock_gen : process
	begin
		wait for clock_period / 2;
		clock <= not clock;
	end process clock_gen;
	
	
	-- Group SPI output into 48-bit std logic vectors for easy verification
	collect_spi_output : process(mosi, clock, sclk, spi_output)
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
		wait until rising_edge(clock); reset_n <= '0'; wait until rising_edge(clock); reset_n <= '1';
		wait until is_transmitting = '0';
		-- Fill buffer
		wait until rising_edge(clock);
		write_address <= 0; write_in <= "010101010101010"; write_cmd <= '1';  wait until rising_edge(clock); write_cmd <= '0';
		write_address <= 1; write_in <= "101010101010101"; write_cmd <= '1';  wait until rising_edge(clock); write_cmd <= '0';
		write_address <= 2; write_in <= "110011001100110"; write_cmd <= '1';  wait until rising_edge(clock); write_cmd <= '0';
		-- Read out buffer
		read_address <= 2; read_cmd <= '1'; wait until rising_edge(clock); read_cmd <= '0'; wait until falling_edge(clock); assert read_out = "110011001100110" report "Test failed: read after write #1";
		read_address <= 1; read_cmd <= '1'; wait until rising_edge(clock); read_cmd <= '0'; wait until falling_edge(clock); assert read_out = "101010101010101" report "Test failed: read after write #2";
		read_address <= 0; read_cmd <= '1'; wait until rising_edge(clock); read_cmd <= '0'; wait until falling_edge(clock); assert read_out = "010101010101010" report "Test failed: read after write #3";
		
		-- -----------------------------------
		-- Test resetting then reading back data
		-- -----------------------------------
		report "Test: read after reset";
		-- Reset and wait for initial transmission to end
		wait until rising_edge(clock); reset_n <= '0'; wait until rising_edge(clock); reset_n <= '1';
		wait until is_transmitting = '0';
		-- Read out buffer
		read_address <= 2; read_cmd <= '1'; wait until rising_edge(clock); read_cmd <= '0'; wait until falling_edge(clock); assert read_out = "110011001100110" report "Test failed: read after reset #1";
		read_address <= 1; read_cmd <= '1'; wait until rising_edge(clock); read_cmd <= '0'; wait until falling_edge(clock); assert read_out = "101010101010101" report "Test failed: read after reset #2";
		read_address <= 0; read_cmd <= '1'; wait until rising_edge(clock); read_cmd <= '0'; wait until falling_edge(clock); assert read_out = "010101010101010" report "Test failed: read after reset #3";

		-- -----------------------------------
		-- Test uploading data
		-- -----------------------------------
		report "Test: upload";
		wait until rising_edge(clock); transmit_cmd <= '1'; wait until rising_edge(clock); transmit_cmd <= '0';
		wait until is_transmitting = '0';
		wait until falling_edge(clock);
		assert spi_output( 0 to 15) = "1010101010101010" report "Test failed: upload #1";
		assert spi_output(16 to 31) = "1101010101010101" report "Test failed: upload #2";
		assert spi_output(32 to 47) = "1110011001100110" report "Test failed: upload #3";

		-- -----------------------------------
		-- Test uploading on reset
		-- -----------------------------------
		report "Test: upload after reset";
		wait until rising_edge(clock); reset_n <= '0'; wait until rising_edge(clock); reset_n <= '1';
		wait until is_transmitting = '0';
		wait until falling_edge(clock);
		assert spi_output( 0 to 15) = "1010101010101010" report "Test failed: upload after reset #1";
		assert spi_output(16 to 31) = "1101010101010101" report "Test failed: upload after reset #2";
		assert spi_output(32 to 47) = "1110011001100110" report "Test failed: upload after reset #3";

		report "Finished running tests.";

		wait;
	
	end process test;
	
	-- Instantiate the sensor register control module
	dut : sensor_comm
		generic map(
			num_reg			=> 3
		)
		port map(
			clock			=> clock,
			reset_n			=> reset_n,
			transmit_cmd	=> transmit_cmd,
			is_transmitting	=> is_transmitting,
			read_cmd		=> read_cmd,
			read_address	=> read_address,
			read_out		=> read_out,
			write_cmd		=> write_cmd,
			write_address	=> write_address,
			write_in		=> write_in,
			sclk			=> sclk,
			miso			=> miso,
			ss				=> ss,
			mosi			=> mosi
		);

end tests;
