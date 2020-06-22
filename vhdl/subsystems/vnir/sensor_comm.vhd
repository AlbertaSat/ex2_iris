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
-- @file sensor_comm.vhd
-- @author Alexander Epp, Campbell Rea
-- @date 2020-06-07
----------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package sensor_comm_types is
	subtype sensor_comm_reg_entry_t is std_logic_vector (14 downto 0);
	type sensor_comm_reg_t is array (integer range <>) of sensor_comm_reg_entry_t;
end package sensor_comm_types;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.sensor_comm_types.all;

-- @brief
--	 Module for configuring registers within the VNIR sensor
-- 
-- @details
--	 Sensor register values are originally contained within an
--	 array named reg_data of size vnir_spi_reg_capacity by 15.  Within an 
--	 array entry, the first 7 bits represent the VNIR sensor 
--	 register address while the last 8 bits represent the desired
--	 register value.  Register values can be read from, and 
--	 written to, this array.  To transfer the contents of reg_data
--	 to the actual VNIR sensor, setting transmit_array <= '1' 
--	 begins a process in which the array addresses are transmitted
--	 sequentially via SPI.  transmit_done = '0' indicates that
--	 register transfer is currently in progress while transmit_done='1'
--	 indicates that the register transfer process has been completed
--	
--	 The module for handling the actual transmission of data via 
--	 SPI was created by Scott Larson and the original page can be
--	 found at Digikey eewiki,
--	 https://www.digikey.com/eewiki/pages/viewpage.action?pageId=4096096
--
-- @attention
--	 NOTE: during the transfer process, register values
--	 cannot be read from or written to reg_data until the 
--	 process is completed.
--
-- @param[in] clock
-- 		main input system clock
-- @param[in] reset_n
-- 		Active low synchronous reset. As soon as the device
--		exits reset, the default register settings are uploaded
--		to the VNIR
--
-- @param[in] transmit_cmd
-- 		Assert to begin transmitting register data out of the
-- 		SPI output.
--		NOTE: during the transfer process, register values
--		cannot be read from or written to reg_data until the 
--		process is completed.
-- @param[out] is_transmitting
-- 		Asserted when register data is currently being
-- 		transmitted along SPI.
-- 			'1' - indicates that register data is
-- 				  currently being transmitted to the VNIR
--			'0' - indicates that the module is in IDLE 
--				  mode. Contents of reg_data can be read/written
--				  and next transfer can take place.
--
-- @param[in] read_cmd
-- 		Assert to return the contents of reg_data at the address
-- 		given by read_address on the output read_out.
-- @param[in] read_address
-- 		Specifies reg_data array address to be read. Range of 0 to
-- 		vnir_spi_reg_capacity-1.
-- @param[out] read_out
-- 		Contains the read contents from reg_data during a read
--		operation.  read_out remains unchanged until another read
--		operation is completed
-- 
-- @param[in] write_cmd
-- 		Assert to change the contents of reg_data at the address
--		given by write_address to the value given by write_in.
-- @param[in] write_address
-- 		Specifies the reg_data array address to be written to.
-- 		Range of 0 to num_reg-1.
-- @param[in] write_in
-- 		Contains the std_logic_vector to be written to reg_data
--		at the address given by write_index
--
-- @param[out] sclk
-- 		SPI output clock for data transfer synchronization
-- @param[in] miso
-- 		SPI master-in, slave-out 
-- @param[out] ss
-- 		active-high SPI slave-select line
-- @param[out] mosi
-- 		SPI master-out, slave-in
entity sensor_comm is
	generic (
		num_reg : integer
	);
	port (	
		clock			: in std_logic;
		reset_n			: in std_logic;
		transmit_cmd	: in std_logic;    
		is_transmitting	: out std_logic;    
		read_cmd		: in std_logic;
		read_address	: in integer;
		read_out		: out std_logic_vector (14 downto 0);
		write_cmd		: in std_logic;
		write_address	: in integer;
		write_in		: in std_logic_vector (14 downto 0);
		reg_write_cmd   : in std_logic;
		reg_write_in    : in sensor_comm_reg_t (0 to num_reg);	
		sclk			: out std_logic;
		miso			: in std_logic;
		ss				: out std_logic;
		mosi			: out std_logic
	);
	
end entity sensor_comm;

architecture rtl of sensor_comm is

	-- Internal array for sensor register data
	signal reg_data : sensor_comm_reg_t (0 to num_reg);  -- first 7 bits are register address, last 8 bits is desired register data
	
	-- signal to store value of busy during previous clk_sys cycle (used in 'busy' signal edge finding)
	signal busy_prev	: STD_LOGIC;	
	
	-- for main finite state machine (FSM) of module
	type   t_state is (IDLE, REPROGRAM, FINISHING);
	signal state : t_state;
	
	-- SPI controller signals
	signal enable	:	std_logic;
	signal cont		:	std_logic;
	signal tx_data	:	std_logic_vector(15 downto 0);
	signal busy		:	std_logic;
	signal rx_data	:	std_logic_vector(15 downto 0);
	signal ss_n		:   std_logic_vector(0 downto 0);
	
	
	-- Add SPI master component
	component spi_master is
	  generic (
		slaves  : integer;  
		d_width : integer);
	  port (
		clock   : in     std_logic;                             
		reset_n : in     std_logic;                             
		enable  : in     std_logic;                             
		cpol    : in     std_logic;                             
		cpha    : in     std_logic;                             
		cont    : in     std_logic;                             
		clk_div : in     integer;                               
		addr    : in     integer;                               
		tx_data : in     std_logic_vector(15 downto 0);  
		miso    : in     std_logic;                             
		sclk    : buffer std_logic;                             
		ss_n    : buffer std_logic_vector(0 downto 0);   
		mosi    : out    std_logic;                             
		busy    : out    std_logic;                             
		rx_data : out    std_logic_vector(15 downto 0)); 
	end component;
	

begin


	-- Contains the main FSM which coordinates the process
	main_process : process (clock, reset_n)
	
		-- Variables for indexing through reg_data (updated immediately in simulation)
		subtype array_index_t is integer range num_reg-1 downto 0;
		variable array_index	: array_index_t := 0;
		
	begin
		if rising_edge(clock) then
			if (reset_n = '0') then
				state <= IDLE;
				is_transmitting <= '0';
				array_index := 0;
			else
				case state is
					when IDLE =>
					
						-- indicate system ready to modify internal array or begin new transmission
						is_transmitting <= '0';
						
						-- Begin register transfer process
						if (transmit_cmd = '1') then						
							state <= REPROGRAM;
							is_transmitting <= '1';
							array_index := 0;
							tx_data <= '1' & reg_data(array_index);														
						end if;
						
						-- Read value at specified array index
						if (read_cmd = '1') then
							read_out <= reg_data(read_address);
						end if;
						
						-- Write data to specified array index
						if (write_cmd = '1') then
							reg_data(write_address) <= write_in;
						end if;

						-- Write to entire register at once
						if (reg_write_cmd = '1') then
							reg_data <= reg_write_in;
						end if;
					
					-- Iterate through reg_data and transmit all contents via SPI
					when REPROGRAM =>
					
						-- Signal SPI master module to start transmitting data in continuous mode
						enable <= '1';
						cont <= '1';							
						
						-- if SPI has finished sending previous value
						if (busy = '1' and busy_prev = '0') then          -- find rising edge of busy					
							if (array_index = num_reg-1) then							
								-- All reg have been transmitted
								state <= FINISHING;							
							else
								-- transmit new reg line to SPI, increment index
								array_index := array_index + 1;
								tx_data <= '1' & reg_data(array_index);														
							end if;																			
						end if;	
											
					-- Deactivate transmission signals to SPI master module wait
					-- until last transfer is finished
					when FINISHING =>
					
						-- Signal to SPI master to stop transmitting after current register is finished
						enable <= '0';
						cont <= '0';
						
						-- when last register has finished transmitting
						if (busy = '0') then							
							--transmit_done <= '1';
							state <= IDLE;							
						end if;
					
					end case;		
			end if;
			
			busy_prev <= busy;
			
		end if;
	end process;
	
	-- Invert ss line to make is active-high as per the CMV2000 datasheet
	ss <= not ss_n(0);
	
	
	-- Instantiate SPI controller
	spi_controller : spi_master
		generic map(
			slaves		=>	1,
			d_width		=>	16)
		port map(
			clock		=>	clock,
			reset_n		=>	reset_n,
			enable		=>	enable,
			cpol		=>	'0',		-- chosen based on CMV2000 datasheet
			cpha		=>	'0',		-- ^
			cont		=>	cont,
			clk_div		=>	0,
			addr		=>	0,
			tx_data		=>	tx_data,
			miso		=>	miso,
			sclk		=>	sclk,
			ss_n		=>	ss_n,
			mosi		=>	mosi,
			busy		=>	busy,
			rx_data		=>	rx_data
		);
	
	
end architecture rtl;
