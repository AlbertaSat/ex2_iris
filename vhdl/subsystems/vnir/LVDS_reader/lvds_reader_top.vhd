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
--	@attention
--		NOTE: Channel word alignment must be performed when the VNIR
--		is idle so that known training patterns appear on the data
--		and control channels
--
--	@param[in] NUM_CHANNELS
--		Number of data channels from VNIR to FPGA
--
--	@param[in] clock_sys
--		Main system clock
--	@param[in] reset_sys
--		Main system synchronous reset
--
--	@param[in]] lvds_signal_in
--		Serial LVDS signals from the VNIR data and control channels
--	@param[in] lvds_clock_in
--		VNIR LVDS clock signal, synchronous to incoming data
--
--`	@param[in] cmd_start_align
--		Pulse HIGH to initiate word alignment on the data and control
--		channels
--	@param[out] alignment_done
--		Pulsed HIGH to indicate that word alignment has been completed
--
--	@param[out] word_alignment_error
--		Held HIGH to indicate that the correct word boundaries could
--		not be found on channel undergoing alignment
--		NOTE: This signal remains HIGH until the component is reset
--	@param[out] pll_locked
--		Held HIGH when the PLL in the ALTLVDS_RX IP is locked to the
--		lvds_clock_in clock signal
--		NOTE: When LOW, the values presented at data_par_{00:15} and
--		ctrl_par will not be valid until approximately 3 parallel 
--		clock cycles after pll_locked returns to HIGH
--
--	@param[out] data_par_{00:15}
--		Parallelized 10-bit output values from the VNIR data channels
--	@param[out] ctrl_par
--		Parallelized 10-bit value from the VNIR control channel
--
----------------------------------------------------------------



library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lvds_reader_top is
	generic (
		NUM_CHANNELS	: integer := 16
	);
	port(
		-- main system clock and reset
		clock_sys		: in std_logic;
		reset_sys		: in std_logic;
		
		-- Input from LVDS data and clock pins
		lvds_signal_in	: in std_logic_vector(16 downto 0);
		lvds_clock_in	: in std_logic;
		
		-- Word alignment signals
		alignment_done	: out std_logic;
		cmd_start_align	: in  std_logic;
		
		-- Status signals
		word_alignment_error    : out std_logic;
		pll_locked				: out std_logic;
		
		-- parallelized output data
		data_par_00		: out std_logic_vector (9 downto 0);
		data_par_01		: out std_logic_vector (9 downto 0);
		data_par_02		: out std_logic_vector (9 downto 0);
		data_par_03		: out std_logic_vector (9 downto 0);
		data_par_04		: out std_logic_vector (9 downto 0);
		data_par_05		: out std_logic_vector (9 downto 0);
		data_par_06		: out std_logic_vector (9 downto 0);
		data_par_07		: out std_logic_vector (9 downto 0);
		data_par_08		: out std_logic_vector (9 downto 0);
		data_par_09		: out std_logic_vector (9 downto 0);
		data_par_10		: out std_logic_vector (9 downto 0);
		data_par_11		: out std_logic_vector (9 downto 0);
		data_par_12		: out std_logic_vector (9 downto 0);
		data_par_13		: out std_logic_vector (9 downto 0);
		data_par_14		: out std_logic_vector (9 downto 0);
		data_par_15		: out std_logic_vector (9 downto 0);
		ctrl_par		: out std_logic_vector (9 downto 0)
	);
end entity lvds_reader_top;

architecture rtl of lvds_reader_top is

	-- Data channel and bitslip control
	signal lvds_bitslip			: std_logic_vector (NUM_CHANNELS downto 0) := (others => '0');
	signal lvds_pll_reset		: std_logic := '0';
	signal lvds_output_clock	: std_logic;
	signal lvds_cda_max			: std_logic_vector (NUM_CHANNELS downto 0);
	signal pll_locked_extended	: std_logic_vector (NUM_CHANNELS downto 0);
	
	-- Signals align_channel_process to perform word alignment on selected channel
	signal start_align			: std_logic;
	
	-- Finite state machine states for main process
	type t_main_process_FSM is (s_IDLE, s_START_ALIGN, s_ALIGN);
	signal main_process_FSM : t_main_process_FSM;
	
	-- Selects data channel to align
	subtype t_channel_select is integer range NUM_CHANNELS downto 0;
	signal channel_select : t_channel_select;
	
	-- copy of data channel being aligned and training pattern from VNIR
	signal current_data 	: std_logic_vector (9 downto 0);
	signal alignment_word 	: std_logic_vector (9 downto 0);
	
	-- Indicates alignment for channel has completed
	signal channel_done		: std_logic;
	
	-- FSM for individual channel alignment
	type t_alignment_FSM is (s_IDLE, s_CHECKVALUE, s_WAIT);
	signal alignment_FSM : t_alignment_FSM;
	
	-- Counter to wait for bitslip to take effect
	subtype t_counter is integer range 3 downto 0;
	signal counter : t_counter;
	
	-- Array to hold data from SERDES
	type t_lvds_data_array is array (NUM_CHANNELS downto 0) of
							std_logic_vector (9 downto 0);
	signal lvds_data_array : t_lvds_data_array := (others => (others => '0'));
	
	-- Basically a constant to check that all pll_locked signals are HIGH because Quartus 
	-- can't handle unary AND operations :(
	constant check_pll_locked : std_logic_vector (NUM_CHANNELS downto 0) := (others => '1');

	-- Component instantiation for ALTLVDS_RX IP
	component lvds_reader_ip
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
		internal_lvds_signal_in <= "" & lvds_signal_in(i_gen);
		
		inst_lvds_ip : lvds_reader_ip port map (
		pll_areset	 			=> lvds_pll_reset,
		rx_channel_data_align	=> internal_lvds_bitslip,
		rx_in	 				=> internal_lvds_signal_in,
		rx_inclock	 			=> lvds_clock_in,
		rx_cda_max	 			=> internal_lvds_cda_max,
		rx_locked	 			=> pll_locked_extended(i_gen),
		rx_out	 				=> lvds_data_array(i_gen),
		rx_outclock	 			=> lvds_output_clock
		);
		
		lvds_cda_max(i_gen)	<= internal_lvds_cda_max(0);
	end generate;
	
	-- Set data in array to correct outputs
	data_par_00 <= lvds_data_array(0);
	data_par_01 <= lvds_data_array(1);
	data_par_02 <= lvds_data_array(2);
	data_par_03	<= lvds_data_array(3);
	data_par_04 <= lvds_data_array(4);
	data_par_05 <= lvds_data_array(5);
	data_par_06 <= lvds_data_array(6);
	data_par_07 <= lvds_data_array(7);
	data_par_08 <= lvds_data_array(8);
	data_par_09 <= lvds_data_array(9);
	data_par_10 <= lvds_data_array(10);
	data_par_11 <= lvds_data_array(11);
	data_par_12 <= lvds_data_array(12);
	data_par_13 <= lvds_data_array(13);
	data_par_14 <= lvds_data_array(14);
	data_par_15 <= lvds_data_array(15);
	ctrl_par	<= lvds_data_array(16);
	
	-- Check if any pll_signal loses lock
	pll_locked <= '1' when pll_locked_extended = check_pll_locked else '0';
	
	
	
	main_process : process (clock_sys)
	begin
		if rising_edge(clock_sys) then
			if (reset_sys = '1') then
				
				-- Set signals to default values
				start_align 		 <= '0';
				alignment_done		 <= '0';
				main_process_FSM 	 <= s_IDLE;
				channel_select 		 <= 0;
				alignment_word		 <= (others => '0');
				current_data		 <= (others => '0');
				lvds_pll_reset		 <= '1';
			
			else
				-- Default values
				start_align 	<= '0';
				alignment_done 	<= '0';
				lvds_pll_reset	<= '0';
				
				-- FSM
				case main_process_FSM is
					when s_IDLE =>
						if (cmd_start_align = '1') then
							main_process_FSM 	<= s_START_ALIGN;
							channel_select		<= 0;
						end if;
						
					when s_START_ALIGN =>
						start_align 		<= '1';
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
					alignment_word		<= (others => '0');
					alignment_word(9)	<= '1';
				else
					alignment_word		<= "0001010101";
				end if;
				
				-- If error in finding word boundary
				if (lvds_cda_max(channel_select) = '1') then
					main_process_FSM <= s_IDLE;
				end if;
				
				-- If PLL loses lock, stop alignment
				if (pll_locked_extended /= check_pll_locked) then
					main_process_FSM <= s_IDLE;
				end if;
					
			end if;
		end if;
	end process;
		
	
	-- Controls word alignment for an individual channel
	align_channel_process : process(clock_sys)
	begin
		if rising_edge(clock_sys) then
			if (reset_sys = '1') then
			
				-- Set signals to default values
				lvds_bitslip 	<= (others => '0');
				channel_done	<= '0';
				alignment_FSM	<= s_IDLE;
				counter			<= 3;
				word_alignment_error <= '0';
				
			else
				-- Set default values
				lvds_bitslip <= (others => '0');
				channel_done <= '0';
				
				-- FSM
				case alignment_FSM is
					when s_IDLE =>
						if (start_align = '1') then
							alignment_FSM <= s_CHECKVALUE;						
						end if;
						
						
					when s_CHECKVALUE =>
						-- Compare the received value with the expected one
						if (current_data = alignment_word) then
							alignment_FSM <= s_IDLE;
							channel_done <= '1';
						else
							-- perform bitslip to match word boundary
							lvds_bitslip(channel_select) <= '1';
							alignment_FSM <= s_WAIT;
							counter <= 3;
						end if;
					
					
					when s_WAIT =>
						-- If module fails to find correct word boundary
						if (lvds_cda_max(channel_select) = '1') then
							word_alignment_error <= '1';
							alignment_FSM        <= s_IDLE;				
						else
							-- Wait for change to take effect
							if (counter = 0) then
								alignment_FSM <= s_CHECKVALUE;
							else
								counter <= counter - 1;
							end if;	
						end if;
						
				end case;
				
				-- If PLL loses lock, stop alignment
				if (pll_locked_extended /= check_pll_locked) then
					alignment_FSM <= s_IDLE;
				end if;
					
			end if;
		end if;
	end process;


end architecture rtl;














