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
-- @file sensor_comm_v1_2.vhd
-- @author Campbell Rea
-- @date 2020-06-07
--	
-- @brief
--	 Module for configuring registers within the VNIR sensor
--	
-- @details
--	 Sensor register values are originally contained within an
--	 array named reg_data of size NUM_REG by 15.  Within an 
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
--		NOTE: during the transfer process, register values
--		cannot be read from or written to reg_data until the 
--		process is completed
-- @attention
--		Upon exiting reset, the module automatically uploads default 
--		sensor values to the sensor
--
-- @param NUM_REG
--		number of registers contained within the internal array
-- @param clk_sys
--		main input system clock
-- @param rst_sys
--		active low system reset
-- @param transmit_array
--		trigger to begin transmission of registers to sensor
-- @param read_reg
--		trigger to read register value within internal array
-- @param read_index
--		internal array index from which the register value should be read
-- @param write_reg
--		trigger to write new register value to internal array
-- @param write_index
--		internal array index from which the new register value should be written to
-- @param reg_in
--		new register value to be written to the internal array
-- @param miso
--		master-in, slave-out line for SPI communication with sensor
--	
-- @return transmit_done
--		indicates the completion of register transfer to sensor
-- @return reg_out
--		register value read from internal array	
-- @return sclk
--		output clock for SPI communication synchronization
-- @return ss
--		active-high SPI slave select line to sensor
-- @return mosi
--		master-out, slave-in line for SPI communication with sensor
--	
-----------------------------------------------------------------
		

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sensor_comm_v1_2 is
	----------------------------------------------------------------
	--	Generics:
	--		NUM_REG: number of registers contained within reg_data
	--
	--	Signals:
	--		clk_sys: main input system clock
	--		rst_sys: active low synchronous reset. As soon as the device
	--			exits reset, the default register settings are uploaded
	--			to the VNIR
	--		transmit_array: '0' - device remains in IDLE mode
	--						'1' - signals module to begin process to
	--							transmit current contents of reg_data
	--							to the VNIR
	--			NOTE: during the transfer process, register values
	--			cannot be read from or written to reg_data until the 
	--			process is completed
	--		transmit_done:	'0' - indicates that register data is
	--							currently being transmitted to the VNIR
	--						'1' - indicates that the module is in IDLE 
	--							mode. contents of reg_data can be read/written
	--							and next transfer can take place
	--		read_reg: '1' - tells module to return contents of reg_data
	--						located at the address given by read_index
	--		read_index: (integer) specifies reg_data array address to be read
	--			range of 0 to NUM_REG-1
	--		reg_out: contains the read contents from reg_data during a read
	--			operation.  reg_out remains unchanged until another read
	--			operation is completed
	--		write_reg: '1' - tells the module to change the contents of
	--			reg_data, located at the index given by write_index, to the 
	--			value given by reg_in
	--		write_index: (integer) specifies the reg_data array address to
	--			be written to. range of 0 to NUM_REG-1
	--		reg_in: contains the std_logic_vector to be written to reg_data
	--			at the address given by write_index
	--		sclk: SPI output clock for data transfer synchronization
	--		miso: SPI master-in, slave-out 
	--		ss: active-high SPI slave-select line
	--		mosi: SPI master-out, slave-in
	--
	----------------------------------------------------------------
	
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
		ss				: out std_logic;		-- active high ss line
		mosi			: out std_logic
		
	);
	
end entity sensor_comm_v1_2;

architecture rtl of sensor_comm_v1_2 is

	-- Internal array for sensor register data
	type register_data_array is array (0 to NUM_REG-1) of
				     std_logic_vector (14 downto 0);
	-- default sensor register values
	signal reg_data : register_data_array := (
		0 => "101010101010101",
		1 => "010101010101010",
		2 => "111111100000001" 
		
		-- add more address rows as needed	(Remember to update NUM_REG accordingly)	
		-- first 7 bits are register address, last 8 bits is desired register data
	);
	
	-- signal to store value of busy during previous clk_sys cycle (used in 'busy' signal edge finding)
	signal busy_prev	: STD_LOGIC := '0';	
	
	-- for main finite state machine (FSM) of module
	type   t_state is (IDLE, REPROGRAM, FINISHING);
	signal state : t_state := IDLE;
	
	-- SPI controller signals
	signal enable	:	std_logic := '0';
	signal cont		:	std_logic := '0';
	signal tx_data	:	std_logic_vector(15 downto 0);
	signal busy		:	std_logic := '0';
	signal rx_data	:	std_logic_vector(15 downto 0);
	signal ss_n		: std_logic_vector(0 downto 0);
	
	
	-- Add SPI master component
	component spi_master is
	  generic(
		slaves  : integer;  
		d_width : integer); 
	  port(
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
	main_process : process (clk_sys,rst_sys)
	
		-- Variables for indexing through reg_data (updated immediately in simulation)
		subtype t_array_index is integer range NUM_REG-1 downto 0;
		variable array_index	: t_array_index := 0;
		
	begin
		if rising_edge(clk_sys) then
			if (rst_sys = '0') then
				-- Upload default register values on reset
				state <= REPROGRAM;
				transmit_done <= '0';
				array_index := 0;
				tx_data <= '1' & reg_data(array_index);
			
			else
			
				case state is
					when IDLE =>
					
						-- indicate system ready to modify internal array or begin new transmission
						transmit_done <= '1';
						
						-- Begin register transfer process
						if (transmit_array = '1') then						
							state <= REPROGRAM;
							transmit_done <= '0';
							array_index := 0;
							tx_data <= '1' & reg_data(array_index);														
						end if;
						
						-- Read value at specified array index
						if (read_reg = '1') then
							reg_out <= reg_data(read_index);
						end if;
						
						-- Write data to specified array index
						if (write_reg = '1') then
							reg_data(write_index) <= reg_in;
						end if;
					
					-- Iterate through reg_data and transmit all contents via SPI
					when REPROGRAM =>
					
						-- Signal SPI master module to start transmitting data in continuous mode
						enable <= '1';
						cont <= '1';							
						
						-- if SPI has finished sending previous value
						if (busy = '1' and busy_prev = '0') then          -- find rising edge of busy					
							if (array_index = NUM_REG-1) then							
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
			clock		=>	clk_sys,
			reset_n		=>	rst_sys,
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
