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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.spi_types.all;
use work.sensor_comm_types.all;

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
	signal reg_write_cmd    : std_logic;
	signal reg_write_in     : sensor_comm_reg_t (0 to 3);
	signal spi				: spi_t;

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
		reg_write_cmd   : in std_logic;
		reg_write_in    : in sensor_comm_reg_t (0 to 3);
		spi_out			: out spi_from_master_t;
		spi_in			: in spi_to_master_t
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
	collect_spi_output : process(clock, spi)
		variable i			: integer range spi_output_size downto 0 := 0;
		variable out_tmp	: std_logic_vector(0 to spi_output_size-1);	
	begin
		if rising_edge(spi.from_master.clock) then		
			
			out_tmp(i) := spi.from_master.data;
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
		-- Reset
		wait until rising_edge(clock); reset_n <= '0'; wait until rising_edge(clock); reset_n <= '1';
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
		-- Reset
		wait until rising_edge(clock); reset_n <= '0'; wait until rising_edge(clock); reset_n <= '1';
		-- Read out buffer
		read_address <= 2; read_cmd <= '1'; wait until rising_edge(clock); read_cmd <= '0'; wait until falling_edge(clock); assert read_out = "110011001100110" report "Test failed: read after reset #1";
		read_address <= 1; read_cmd <= '1'; wait until rising_edge(clock); read_cmd <= '0'; wait until falling_edge(clock); assert read_out = "101010101010101" report "Test failed: read after reset #2";
		read_address <= 0; read_cmd <= '1'; wait until rising_edge(clock); read_cmd <= '0'; wait until falling_edge(clock); assert read_out = "010101010101010" report "Test failed: read after reset #3";

		-- -----------------------------------
		-- Test uploading data
		-- -----------------------------------
		report "Test: upload";
		wait until rising_edge(clock); transmit_cmd <= '1'; wait until rising_edge(clock); transmit_cmd <= '0';
		wait until rising_edge(clock) and is_transmitting = '0';
		assert spi_output( 0 to 15) = "1010101010101010" report "Test failed: upload #1";
		assert spi_output(16 to 31) = "1101010101010101" report "Test failed: upload #2";
		assert spi_output(32 to 47) = "1110011001100110" report "Test failed: upload #3";

		-- -- -----------------------------------
		-- -- Test uploading on reset
		-- -- -----------------------------------
		-- report "Test: upload after reset";
		-- wait until rising_edge(clock); reset_n <= '0'; wait until rising_edge(clock); reset_n <= '1';
		-- wait until is_transmitting = '0';
		-- wait until falling_edge(clock);
		-- assert spi_output( 0 to 15) = "1010101010101010" report "Test failed: upload after reset #1";
		-- assert spi_output(16 to 31) = "1101010101010101" report "Test failed: upload after reset #2";
		-- assert spi_output(32 to 47) = "1110011001100110" report "Test failed: upload after reset #3";

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
		reg_write_cmd   => reg_write_cmd,
		reg_write_in	=> reg_write_in,
		spi_out			=> spi.from_master,
		spi_in			=> spi.to_master
	);

end tests;
