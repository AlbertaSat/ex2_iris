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

-- Should i get reset from swir?
-- How to use adc_trigger -> as a safety check? (count both?) - Can't, its too fast - Add to synchronizing ff
-- Add clock domain crossing -> domain crossing from SWIR too!
-- Ensure pull up resitor brings pins to high for cyclone v pins
-- Error: changing sdi after 1 clk cycle is too slow, unless adc_clock is at least 2 MHz
-- ADD: Ad_trig signal handelling


-- Circuit to control ADAQ7980 ADC, in 4-wire CS mode with busy indicator, with VIO above 1.7V

-- Note: Should maintain one clock cycle of sck between conversion to allow for sdi to go high

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity swir_adc is
    port (
        clock_adc	      	: in std_logic;  -- sck
		clock_main			: in std_logic;  -- Main 50 MHz clock, needed to feed into FIFO IP
        reset_n         	: in std_logic;
		
        output_done		   	: out std_logic;  -- Indicate that one pixel has been received
		
		-- Signals from sensor
		adc_trigger			: in std_logic;
		adc_start			: in std_logic;
		
		-- Signals from ADC
		sdi					: out std_logic;						
		cnv					: out std_logic;
		sdo					: in std_logic;
		
		-- FIFO signals for higher level file to read from
		fifo_rdreq			: in std_logic;
		fifo_rdempty		: out std_logic;
		fifo_data_read		: out std_logic_vector(15 downto 0)
    );
end entity swir_adc;

architecture main of swir_adc is

	component dcfifo_mixed_widths
	generic (
		intended_device_family		: string;
		lpm_numwords				: natural;
		lpm_showahead				: string;
		lpm_type					: string;
		lpm_width					: natural;
		lpm_widthu					: natural;
		lpm_widthu_r				: natural;
		lpm_width_r					: natural;
		overflow_checking			: string;
		rdsync_delaypipe			: natural;
		underflow_checking			: string;
		use_eab						: string;
		wrsync_delaypipe			: natural
	);
	port (
		data						: in std_logic_vector (0 downto 0);
		rdclk						: in std_logic;
		rdreq						: in std_logic;
		wrclk						: in std_logic;
		wrreq						: in std_logic;
		q							: out std_logic_vector (15 downto 0);
		rdempty						: out std_logic;
		wrfull						: out std_logic 
	);
	end component;

	-- State Machine signals
	type adc_control_state is (idle, conversion, acquisition);
	signal state_reg, state_next:	adc_control_state;
	
	-- FIFO Signals
	signal fifo_data_write	: std_logic_vector(0 downto 0);
	signal fifo_wrreq		: std_logic;
	signal fifo_wrfull		: std_logic;
	
	signal one_clock_cycle_passed	: std_logic;
	signal one_pixel_cycle_passed	: std_logic;
	signal readout					: std_logic;
	signal timer					: natural;
	
	signal reset_n_local			: std_logic;
	signal reset_n_metastable		: std_logic;
	signal adc_start_local			: std_logic;
	signal adc_start1				: std_logic;
	signal adc_start2				: std_logic;
	signal adc_start3				: std_logic;

begin

	-- FIFO Information: 
	-- 		1 bit wide input, 16 bit wide output
	-- 		128 words deep
	-- 		Dual Clock
	--		2 clock sync stages, good metastability protection, medium size, good fmax
	--		empty (for read) and full (for write) signals
	--		Normal synchronous FIFO mode
	--		Automatic memory block type
	--		Resource Usage: 4 LUT's, 1 M10K memory block, 46 reg's
	adc_data_buffer : dcfifo_mixed_widths
	generic map (
		intended_device_family 		=> "cyclone v",
		lpm_numwords 				=> 128,
		lpm_showahead 				=> "off",
		lpm_type 					=> "dcfifo_mixed_widths",
		lpm_width 					=> 1,
		lpm_widthu 					=> 7,
		lpm_widthu_r 				=> 3,
		lpm_width_r 				=> 16,
		overflow_checking 			=> "on",
		rdsync_delaypipe 			=> 4,
		underflow_checking 			=> "on",
		use_eab 					=> "on",
		wrsync_delaypipe 			=> 4
	)
	port map (
		data 						=> fifo_data_write,
		rdclk 						=> clock_main,
		rdreq 						=> fifo_rdreq,
		wrclk 						=> clock_adc,
		wrreq 						=> fifo_wrreq,
		q 							=> fifo_data_read,
		rdempty 					=> fifo_rdempty,
		wrfull						=> fifo_wrfull
	);

	-- Get stable signals from signals which cross clock domains
	process(clock_adc) is
	begin
		
		if (rising_edge(clock_adc)) then
			reset_n_metastable <= reset_n;
			reset_n_local <= reset_n_metastable;
			
			adc_start1 <= adc_start;
			adc_start2 <= adc_start1;
			adc_start3 <= adc_start2;
			
			-- Register rising edge of adc_start signal
			if (adc_start3 = '0' and adc_start2 = '1') then
				adc_start_local <= '1';
			else
				adc_start_local <= '0';
			end if;
			 
		end if;
		
	end process;

	-- State machine flip-flop, aligned with ADC clock
	process(clock_adc, reset_n_local)
	begin
		if reset_n_local = '0' then
			state_reg <= idle;
		elsif rising_edge(clock_adc) then
			state_reg <= state_next;
		end if;
	end process; 
	
	-- State machine next state logic
	process(state_reg, sdo, adc_start_local, one_pixel_cycle_passed) 
	begin 
		state_next <= state_reg; -- default state_next
		-- default outputs
		cnv <= '0';
		sdi <= '1';
		readout <= '0';
		
		case state_reg is
			when idle =>  -- Default state
				sdi <= '1';
				readout <= '0';
				if adc_start_local = '1' then -- Trigger to indicate beginning of data transmission
					cnv <= '1';  -- Start a conversion with rising edge on cnv while sdi is high
					state_next <= conversion; 
					
				else -- Else stay idle
					cnv <= '0';
					state_next <= idle; 
					
				end if;
				
			when conversion =>  -- Main conversion state; keep cnv high and sdi low, until sdo interrupt is received
				cnv <= '1';
				sdi <= '0';
				readout <= '0';
				if sdo = '0' then
					state_next <= acquisition; 
					
				else
					state_next <= conversion; 
					
				end if;
				
			when acquisition =>  -- Main acquisition state for data being outputted; Held for 17 clock cycles (one pixel length + inital interrupt cycle)
				sdi <= '0';
				readout <= '1';
				if one_pixel_cycle_passed = '1' then
					cnv <= '0';
					state_next <= idle;
					
				else
					cnv <= '1';
					state_next <= acquisition; 
					
				end if;
		end case;
	end process;
	
	-- Timer process; counts number of clock cycles each state is held in
	process(clock_adc, reset_n_local)
	begin
		if reset_n_local = '0' then
            timer <= 0;
        elsif rising_edge(clock_adc) then
            if state_reg /= state_next then  -- state is changing
                timer <= 0;
            else
                timer <= timer + 1; 
            end if; 
        end if; 
	end process;
	
	-- Process to write data from ADC to buffer; Data is read on falling edge of sck
	process(clock_adc, reset_n_local)
	begin
		if reset_n_local = '0' then
            fifo_data_write <= (others => '0');
        elsif falling_edge(clock_adc) then
            if readout = '1' then
                fifo_data_write <= (others => sdo);
            else
                fifo_data_write <= (others => '0'); 
            end if; 
        end if; 
	end process;
			
	
	-- To control how long certain states are held for
	one_pixel_cycle_passed <= '1' when timer = 16 else '0';
	
	-- Indicate that ADC has outputted all data
	output_done <= '1' when one_pixel_cycle_passed = '1' and readout = '1' else '0';
	
	-- FIFO write request signal; Ensure that FIFO is not full first
	fifo_wrreq <= '1' when readout = '1' and fifo_wrfull = '0' else '0';  
	

end architecture main;