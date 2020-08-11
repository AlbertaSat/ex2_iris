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
-- How to use adc_trigger -> as a safety check? (count both?) - Can't, its too fast
-- Bound integers
-- Confusion on how many conversions ADC can do
-- Need to get ADC to sample on falling edge of clk
-- Add reset conditions to processes

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity swir_adc is
    port (
        clock_adc	      	: in std_logic; -- Same as clock_swir  - no
		clock_main			: in std_logic;
		clock_swir			: in std_logic;
        reset_n         	: in std_logic;
			
        row             	: out swir_row_t;
        row_available   	: out std_logic;
		
		adc_trigger			: in std_logic;
		adc_start			: in std_logic;
		
		sdi					: out std_logic;						
		sdo					: out std_logic;	
		cnv					: out std_logic;
		
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
		rdclk						: in std_logic ;
		rdreq						: in std_logic ;
		wrclk						: in std_logic ;
		wrreq						: in std_logic ;
		q							: out std_logic_vector (15 downto 0);
		rdempty						: out std_logic ;
		wrfull						: out std_logic 
	);
	end component;

	signal adc_working		: std_logic;	-- Set to 1 while data is flowing from sensor
	
	signal bit_count		: integer;	-- Counts number of bits from ADC, up to 16
	signal pixel_count		: integer;	-- Counts number of pixels from sensor, up to 512
	
	signal data_readout		: std_logic;
	
	signal fifo_wrfull		: std_logic;
	signal fifo_wrreq		: std_logic;

begin

	-- FIFO Information: 
	-- 		1 bit wide input, 16 bit wide output
	-- 		16384 words deep
	-- 		Dual Clock
	--		2 clock sync stages, good metastability protection, medium size, good fmax
	--		empty (for read) and full (for write) signals
	--		Normal synchronous FIFO mode
	--		Automatic memory block type
	--		Resource Usage: 12 LUT's, 2 M19K memory blocks, 116 reg's
	adc_data_buffer : dcfifo_mixed_widths
	generic map (
		intended_device_family 		=> "cyclone v",
		lpm_numwords 				=> 16384,
		lpm_showahead				=> "off",
		lpm_type 					=> "dcfifo_mixed_widths",
		lpm_width 					=> 1,
		lpm_widthu					=> 14,
		lpm_widthu_r 				=> 10,
		lpm_width_r 				=> 16,
		overflow_checking 			=> "on",
		rdsync_delaypipe 			=> 4,
		underflow_checking 			=> "on",
		use_eab						=> "on",
		wrsync_delaypipe 			=> 4
	)
	port map (
		data 						=> , --FILL IN!
		rdclk 						=> clock_main,
		rdreq 						=> fifo_rdreq,
		wrclk 						=> clock_adc,
		wrreq 						=> fifo_wrreq,
		q 							=> fifo_data_read,
		rdempty 					=> fifo_rdempty,
		wrfull						=> fifo_wrreq
	);


	-- Register if sensor is outputting data or not
	process(clock_swir) is
	begin
		
		if (rising_edge(clock_swir)) then
			if (adc_start = '1') then
				adc_working <= '1';
				pixel_count <= 0;
			elsif (pixel_count = 512) then
				adc_working <= '0';
			end if;
		end if;
		
	end process;
	
	-- Register number of pixels
	process(clock_swir) is
	begin
		
		if (rising_edge(clock_swir)) then
			if (adc_working = '1') then
				pixel_count <= pixel_count + 1;
			end if;
		end if;
		
	end process;
	
	-- Generate cnv signal to ADC
	process(clock_swir) is
	begin
		-- RESET: set cnv to 0
		if (falling_edge(clock_swir)) then
			if (adc_working = '1') then
				cnv <= not cnv;
			else
				cnv <= '0'
			end if;
		end if;
		
	end process;
	
	-- PROCESS: Create sdi signal
	
	-- Receive ADC data bits
	process(clock_adc) is
	begin
		-- RESET: set cnv to 0
		if (falling_edge(clock_adc)) then
			if (adc_working = '1') then
				cnv <= not cnv;
			else
				cnv <= '0'
			end if;
		end if;
		
	end process;

end architecture main;