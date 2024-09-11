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
--	 @file lvds_reader_top.vhd
--   @author Campbell Rea
--   @date 2020-08-08
--
--   @brief
--		Module for instantiating the ALTLVDS_RX IP and for performing
--		word alignment on the incoming data from the VNIR sensor.
--
--   @details
--		This module is responsible for instantiating the ALTLVDS_RX IP
--		in which LVDS signals are converted to single-ended signals and
--		deserialized to produce a 10-bit std_logic_vector for each incoming
--		channel.  The module also handles word alignment by iterating 
--		through each data and control channel and checking the received
--		values against a predetermined value sent by the VNIR whenever
--		it is idle.  If the received value does not match the expected
--		value, the ALTLVDS_RX IP performs bitslip until the received
--		value is as expected.  If the correct word boundaries cannot be
--		bound, word_alignment_error is held HIGH to indicate the error 
--		until the module is reset.
--		Inspiration was taken from AMS tsc_mv1_rx.vhd
--
--		NOTE: There are 3 different clock domains used within this code:
--			* The main system clock (~50 MHz) (system_clock):
--				system_reset, cmd_start_align
--			* The recovered parallel data clock (~48 MHz) (lvds_parallel_clock):
--				word_alignment_error, pll_locked, alignment_done, 
--				lvds_parallel_data
--			* The serial LVDS clock (~240 MHz) (lvds_clock_in):
--				lvds_data_in [DDR], lvds_ctrl_in [DDR]
--
--	@attention
--		NOTE: Channel word alignment must be performed when the VNIR
--		is idle so that known training patterns appear on the data
--		and control channels.
--
--	@param[in] NUM_CHANNELS
--		Number of data channels from VNIR to FPGA.
--	@param[in] DATA_TRAINING_PATTERN
--		Known pattern sent by the VNIR for conducting word alignment.
--
--	@param[in] system_clock
--		Main system clock.
--	@param[in] system_reset
--		Main system synchronous reset.
--
--	@param[in] lvds_data_in
--		Serial LVDS signals from the VNIR data channels.
--	@param[in] lvds_ctrl_in
--		Serial LVDS signal from the VNIR control channel.
--	@param[in] lvds_clock_in
--		LVDS clock signal from VNIR, synchronous to incoming data.
--
--`	@param[in] cmd_start_align
--		Pulse HIGH to initiate word alignment on the data and control
--		channels.
--	@param[out] alignment_done
--		Pulsed HIGH to indicate that word alignment has been completed
--		successfully.
--
--	@param[out] word_alignment_error
--		Held HIGH to indicate that the correct word boundaries could
--		not be found on channel undergoing alignment.
--		NOTE: This signal remains HIGH until the component is reset.
--	@param[out] pll_locked
--		Held HIGH when the PLL in the ALTLVDS_RX IP is locked to the
--		lvds_clock_in clock signal.
--		NOTE: When LOW, the values presented at data_par_{00:15} and
--		ctrl_par will not be valid until approximately 3 parallel 
--		clock cycles after pll_locked returns to HIGH.
--
--	@param[out] lvds_parallel_clock
--		Recovered clock which is synchronous to the parallel output data
--		at lvds_parallel_data.
--	@param[out] lvds_parallel_data
--		Array containing the parallelized 10-bit output values from the 
--		VNIR data and control channels.
--
----------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.LVDS_data_array_pkg.all;

entity lvds_reader_top is
	generic (
		NUM_CHANNELS			: integer := 16;
		DATA_TRAINING_PATTERN	: std_logic_vector (9 downto 0) := "0001010101"
	);
	port(
		-- main system clock and reset
		system_clock			: in std_logic;
		system_reset			: in std_logic;
		
		-- Input from LVDS data, control, and clock pins
		lvds_data_in			: in std_logic_vector(NUM_CHANNELS-1 downto 0);
		lvds_ctrl_in			: in std_logic;
		lvds_clock_in			: in std_logic;
		
		-- Word alignment signals
		alignment_done			: out std_logic;
		cmd_start_align			: in  std_logic;
		
		-- Status signals
		word_alignment_error	: out std_logic;
		pll_locked				: out std_logic;
		
		-- Output parallel LVDS clock
		lvds_parallel_clock		: out std_logic;
		
		-- parallelized output data
		lvds_parallel_data		: out t_lvds_data_array(NUM_CHANNELS downto 0)(9 downto 0)
	);
end entity lvds_reader_top;

architecture rtl of lvds_reader_top is

	-- Data channel and bitslip control
	signal lvds_bitslip				: std_logic_vector (NUM_CHANNELS downto 0);
	signal lvds_pll_reset			: std_logic;
	signal lvds_cda_max				: std_logic_vector (NUM_CHANNELS downto 0);
	signal pll_locked_extended		: std_logic_vector (NUM_CHANNELS downto 0);
	signal i_lvds_parallel_clock	: std_logic_vector (NUM_CHANNELS downto 0);
	
	-- Signals align_channel_process to perform word alignment on selected channel
	signal align_channel	: std_logic;
	
	-- Finite state machine states for main process
	type t_main_process_FSM is (s_IDLE, s_START_ALIGN, s_ALIGN);
	signal main_process_FSM : t_main_process_FSM;
	
	-- Selects data channel to align
	subtype t_channel_select is integer range NUM_CHANNELS downto 0;
	signal channel_select : t_channel_select;
	
	-- copy of data channel being aligned and training pattern from VNIR
	signal current_data 	: std_logic_vector (9 downto 0);
	signal alignment_word 	: std_logic_vector (9 downto 0);
	
	-- Signals to track if the PLL loses lock
	signal pll_lost_lock_1	: std_logic;
	signal pll_lost_lock_2	: std_logic;
	
	-- Indicates alignment for channel has completed
	signal channel_done		: std_logic;
	
	-- FSM for individual channel alignment
	type t_alignment_FSM is (s_IDLE, s_CHECKVALUE, s_WAIT);
	signal alignment_FSM 	: t_alignment_FSM;
	
	-- Counter to wait for bitslip to take effect
	subtype t_counter is integer range 3 downto 0;
	signal counter 			: t_counter;
	
	-- Signals to track rollover of the bitslip counter
	-- NOTE: Resetting ALTLVDS_RX does not reset the bitslip counter
	-- 	which may result in a false word alignment error
	signal bitslip_rollover		: std_logic;
	signal lvds_cda_max_prev	: std_logic;
	
	-- Array to hold data from SERDES
	signal lvds_data_array 	: t_lvds_data_array(NUM_CHANNELS downto 0)(9 downto 0);
	
	-- Basically a constant to check that all pll_locked signals are HIGH because Quartus 
	-- can't handle unary AND operations :(
	constant check_pll_locked : std_logic_vector (NUM_CHANNELS downto 0) := (others => '1');
	
	-----------------------------------------------------------------
	-- 	Component instantiation for ALTLVDS_RX IP
	--		https://www.intel.com/content/dam/www/programmable/us/en/pdfs/literature/ug/ug_altlvds.pdf
	--
	--	LVDS input buffer and deserializer IP.
	--
	--	pll_areset: asynchronous reset
	--	rx_channel_data_align: pulse HIGH to shift the word boundary
	--		by one bit.
	--	rx_in: serial LVDS signal input
	--	rx_inclock: LVDS input clock which is synchronous to the
	--		data at rx_in.
	--	rx_cda_max: indicates that the internal bitslip counter has
	--		rolled-over back to 0.
	--	rx_locked: Stays HIGH to indicate that the internal PLL has 
	--		locked on to rx_inclock
	--	rx_out: parallelized output of the serial LVDS signal.
	--	rx_outclock: Recovered parallel output clock from the PLL.
	--		Synchronous to the data at rx_out.
	-- 
	-----------------------------------------------------------------
	component lvds_reader_ip is
	port
	(
		pll_areset				: in  std_logic;
		rx_channel_data_align	: in  std_logic_vector (0 downto 0);
		rx_in					: in  std_logic_vector (0 downto 0);
		rx_inclock				: in  std_logic;
		rx_cda_max				: out std_logic_vector (0 downto 0);
		rx_locked				: out std_logic;
		rx_out					: out std_logic_vector (9 downto 0);
		rx_outclock				: out std_logic 
	);
	end component;

begin

	-- Instantiate LVDS Serdes IPs for each data and control channel
	gen_lvds_ip : for i_gen in NUM_CHANNELS downto 0 generate
		signal internal_lvds_bitslip 	: std_logic_vector (0 downto 0);
		signal internal_lvds_signal_in 	: std_logic_vector (0 downto 0);
		signal internal_lvds_cda_max	: std_logic_vector (0 downto 0);
	begin
		-- Done to avoid error and convert std_logic to std_logic_vector (0 downto 0)
		internal_lvds_bitslip 	<= "" & lvds_bitslip(i_gen);
		
		-- Check if data or control channel
		gen_test_index1 : if (i_gen = NUM_CHANNELS) generate
			internal_lvds_signal_in(0) <= lvds_ctrl_in;
		end generate gen_test_index1;
		
		gen_test_index2 : if (i_gen < NUM_CHANNELS) generate
			internal_lvds_signal_in(0) <= lvds_data_in(i_gen);
		end generate gen_test_index2;
		
		inst_lvds_ip : lvds_reader_ip port map (
		pll_areset	 			=> lvds_pll_reset,
		rx_channel_data_align	=> internal_lvds_bitslip,
		rx_in	 				=> internal_lvds_signal_in,
		rx_inclock	 			=> lvds_clock_in,
		rx_cda_max	 			=> internal_lvds_cda_max,
		rx_locked	 			=> pll_locked_extended(i_gen),
		rx_out	 				=> lvds_data_array(i_gen),
		rx_outclock	 			=> i_lvds_parallel_clock(i_gen)
		);
		
		lvds_cda_max(i_gen)	<= internal_lvds_cda_max(0);
	end generate gen_lvds_ip;
	
	
	-- Check if any pll_signal loses lock
	pll_locked <= '1' when pll_locked_extended = check_pll_locked else '0';
	
	-- Transfer parallelized data array to output
	lvds_parallel_data 	<= lvds_data_array;
	
	-- Send PLL parallel clock to output
	lvds_parallel_clock	<= i_lvds_parallel_clock(0);
	
	
	main_process : process (system_clock, i_lvds_parallel_clock(0), system_reset)
	begin
			
		if (system_reset = '1') then
				
			-- Set signals to default values
			align_channel 		 <= '0';
			alignment_done		 <= '0';
			main_process_FSM 	 <= s_IDLE;
			channel_select 		 <= 0;
			alignment_word		 <= (others => '0');
			current_data		 <= (others => '0');
			lvds_pll_reset		 <= '1';
			pll_lost_lock_1		 <= '0';
			
		else
			-- Outside rising_edge elsewise PLL never exits reset
			lvds_pll_reset	<= '0';
			
			-- If PLL loses lock, stop alignment
			-- Outside of rising_edge since lvds_clock_output might stop			
			if (main_process_FSM = s_IDLE) then
				pll_lost_lock_1 <= '0';
			else
				if (pll_locked_extended /= check_pll_locked) then
					pll_lost_lock_1 <= '1';
				end if;
			end if;
		
			if rising_edge(i_lvds_parallel_clock(0)) then
			
				-- Default values
				align_channel 	<= '0';
				alignment_done 	<= '0';
								
				-- FSM
				case main_process_FSM is
					when s_IDLE =>
						if (cmd_start_align = '1') then
							main_process_FSM 	<= s_START_ALIGN;
							channel_select		<= 0;
						end if;
						
					when s_START_ALIGN =>
						align_channel 		<= '1';
						main_process_FSM 	<= s_ALIGN;
					
					-- Iterate through and align each data channel
					when s_ALIGN =>
						if (channel_done = '1') then
							if (channel_select = NUM_CHANNELS) then
								main_process_FSM <= s_IDLE;
								alignment_done <= '1';
							else
								channel_select	<= channel_select + 1;
								main_process_FSM <= s_START_ALIGN;
							end if;
						end if;
				end case;
					
				-- Select data channel to be aligned
				current_data <= lvds_data_array(channel_select);
				
				-- Generate training word (known word generated by VNIR)
				if (channel_select = NUM_CHANNELS) then
					alignment_word		<= (9 => '1', others => '0');
				else
					alignment_word		<= DATA_TRAINING_PATTERN;  -- Default is "0001010101"
				end if;
				
				-- If error in finding word boundary
				if ((lvds_cda_max(channel_select) = '1') and (bitslip_rollover = '1')) then
					main_process_FSM <= s_IDLE;
				end if;
				
				-- If the PLL loses lock, stop alignment
				if (pll_lost_lock_1 = '1') then
					main_process_FSM <= s_IDLE;
				end if;
					
			end if;
		end if;
	end process;
		
	
	-- Controls word alignment for an individual channel
	align_channel_process : process(i_lvds_parallel_clock(0), system_reset)
	begin
		
		if (system_reset = '1') then
			
			-- Set signals to default values
			lvds_bitslip 			<= (others => '0');
			channel_done			<= '0';
			alignment_FSM			<= s_IDLE;
			counter					<= 3;
			word_alignment_error 	<= '0';
			pll_lost_lock_2			<= '0';
			bitslip_rollover		<= '0';
			
		else
			-- If PLL loses lock, stop alignment
			-- Outside of rising_edge since lvds_clock_output might stop
			if (alignment_FSM = s_IDLE) then
				pll_lost_lock_2 <= '0';
			else
				if (pll_locked_extended /= check_pll_locked) then
					pll_lost_lock_2 <= '1';
				end if;
			end if;
		
		
			if rising_edge(i_lvds_parallel_clock(0)) then
				
				-- Set default values
				lvds_bitslip <= (others => '0');
				channel_done <= '0';
				
				-- FSM
				case alignment_FSM is
					when s_IDLE =>
						if (align_channel = '1') then
							alignment_FSM 		<= s_CHECKVALUE;	
							bitslip_rollover	<= '0';
						end if;
						
						
					when s_CHECKVALUE =>
						-- Compare the received value with the expected one
						if (current_data = alignment_word) then
							alignment_FSM 	<= s_IDLE;
							channel_done 	<= '1';
						else
							-- perform bitslip to match word boundary
							lvds_bitslip(channel_select) <= '1';
							alignment_FSM 	<= s_WAIT;
							counter 		<= 3;
						end if;
					
					
					when s_WAIT =>
					
						-- Wait for change to take effect
						if (counter = 0) then
							alignment_FSM <= s_CHECKVALUE;
						else
							counter <= counter - 1;
						end if;
					
						-- If module fails to find correct word boundary
						if ((lvds_cda_max(channel_select) = '1') and (bitslip_rollover = '1'))then
							-- Allow the CDA counter to rollover twice before 
							--flagging error since the counter can't be reset
							word_alignment_error 	<= '1';
							alignment_FSM        	<= s_IDLE;	
							bitslip_rollover		<= '0';
							
						-- Detect falling edge of lvds_cda_max for first bitslip rollover
						elsif ((lvds_cda_max(channel_select) = '0') and (lvds_cda_max_prev = '1')) then
							bitslip_rollover	<= '1';						
						end if;
						
				end case;
				
				if (pll_lost_lock_2 = '1') then
					alignment_FSM 	<= s_IDLE;
				end if;
							
				
				lvds_cda_max_prev <= lvds_cda_max(channel_select);
				
					
			end if;
		end if;
	end process;


end architecture rtl;
