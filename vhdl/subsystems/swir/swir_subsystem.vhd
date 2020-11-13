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

-- TODO: Generate clocks

-- Check stability time of sensor after powerup
-- Link voltage and reset - dont want circuit going while no power
-- Make reset synchronous
-- Check that state machine has no downtime between rows
-- Check 0.1< frame_clocks < max frame_clocks = 850 kHz
--   HOWEVER, there may be further delays from fact that maximum conversion time is 800 ns
--   So, need to make sure SWIR does not go too fast for ADC to do conversion
-- Delete config done signal?
-- bound integers
-- set conversion efficiency
-- reset asynchronous - ff only once?
-- remove clocks per frame
-- Note: integration time multiple of 64

-- Startup sequence: reset, obtain config
-- voltage startup time?

-- TPS73601DCQR (1V2) and TPS62821DLCR (4V0) are used as voltage regulators

-- ~1024 max rows

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.swir_types.all;


entity swir_subsystem is
    port (
        clock           	: in std_logic;
        reset_n         	: in std_logic;
			
        config          	: in swir_config_t;
        control         	: out swir_control_t;
			
        do_imaging      	: in std_logic;
	
        pixel           	: out swir_row_t;
        pixel_available 	: out std_logic;
		
		-- Signals to ADC
		sdi					: out std_logic;
		sdo					: in std_logic;
		sck					: out std_logic;
		cnv					: out std_logic;
		
		-- Signals to SWIR sensor
        sensor_clock_even   : out std_logic;
		sensor_clock_odd    : out std_logic;
        sensor_reset_even   : out std_logic;
		sensor_reset_odd    : out std_logic;
		Cf_select1			: out std_logic;
		Cf_select2			: out std_logic;
		AD_sp_even			: in std_logic;
		AD_sp_odd			: in std_logic;
		AD_trig_even		: in std_logic;
		AD_trig_odd			: in std_logic;
		
		-- SWIR Voltage control
		SWIR_4V0			: out std_logic;	
		SWIR_1V2			: out std_logic
    );
end entity swir_subsystem;


architecture rtl of swir_subsystem is

	component pll_0002 is
		port (
			refclk   : in  std_logic; 		-- clk
			rst      : in  std_logic; 		-- reset
			outclk_1 : out std_logic;		-- clk
			outclk_2 : out std_logic;		-- clk
			locked   : out std_logic;		-- export
			outclk_0 : out std_logic 		-- clk
		);
	end component pll_0002;

	component swir_sensor is
    port (
		clock_swir      	: in std_logic;
        reset_n         	: in std_logic;
        
        integration_time    : in unsigned(6 downto 0);
		
		ce					: in std_logic; 
		adc_trigger			: out std_logic;
		adc_start			: out std_logic;
		sensor_begin      	: in std_logic; 
		sensor_done			: out std_logic;
		
		-- Signals to SWIR sensor
        sensor_reset_even   : out std_logic;
		sensor_reset_odd    : out std_logic;
		Cf_select1			: out std_logic;
		Cf_select2			: out std_logic;
		AD_sp_even			: in std_logic;
		AD_sp_odd			: in std_logic;
		AD_trig_even		: in std_logic;
		AD_trig_odd			: in std_logic
    );
	end component swir_sensor;

	component swir_adc is
	port (
		clock_adc	      	: in std_logic; 
		clock_main			: in std_logic;  
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
	end component swir_adc;
	
	signal sensor_clock			: std_logic;
	signal sensor_integration	: unsigned(6 downto 0);
	signal sensor_ce			: std_logic;
	signal sensor_begin			: std_logic;
	signal sensor_done			: std_logic;
	signal sensor_adc_trigger	: std_logic;
	signal sensor_adc_start		: std_logic;
	
	signal adc_done				: std_logic;
	signal adc_fifo_rd			: std_logic;
	signal adc_fifo_empty		: std_logic;
	
	signal row_counter			: unsigned(9 downto 0);
	signal clocks_per_frame_temp: integer;
	signal clocks_per_frame		: integer;
	signal clocks_per_exposure_temp	: integer;
	signal clocks_per_exposure	: integer;
	signal number_of_rows_temp	: integer;
	signal number_of_rows		: integer;
	
	signal counter_sensor_begin : integer range 0 to 1001;
	signal sensor_begin_local	: std_logic;
	
	signal sensor_done1			: std_logic;
	signal sensor_done2			: std_logic;
	signal sensor_done3			: std_logic;
	signal sensor_done_local	: std_logic;
	signal output_done1			: std_logic;
	signal output_done2			: std_logic;
	signal output_done3			: std_logic;
	signal output_done_local	: std_logic;
	signal reset_n1				: std_logic;
	signal reset_n2				: std_logic;
	signal reset_n3				: std_logic;
	signal reset_n_synchronous	: std_logic;
	signal reset_counter		: unsigned(10 downto 0);
	
	signal reset				: std_logic;
	signal pll_locked			: std_logic;
	
begin	
	
	-- PLL details: 50 MHz reference clock frequency, Integer-N PLL in direct mode
	-- M = 14, D = 1
	-- Counter 0 (cascade counter into counter 2): C = 32; Counter 1: C = 28; Counter 2: C = 16
	-- No phase shifts, 50% duty cycles
	pll_inst : component pll_0002
	port map (
		refclk   => clock,   		-- 50 MHz input frequency
		rst      => reset,			-- asynchronous reset
		outclk_1 => sensor_clock,	-- 0.78125 MHz SWIR sensor clock
		outclk_2 => sck,			-- 43.75 MHz ADC clock
		locked   => pll_locked,		-- Signal goes high if locked
		outclk_0 => open			-- Terminated (used as cascade counter)
	);
	
	sensor_control_circuit : component swir_sensor
    port map (
        clock_swir      	=>	sensor_clock,
        reset_n         	=>  reset_n,
        
        integration_time    =>	sensor_integration,
		
		ce					=>	sensor_ce,
		adc_trigger			=>	sensor_adc_trigger,
		adc_start			=>	sensor_adc_start,
		sensor_begin   		=>	sensor_begin,
		sensor_done			=>	sensor_done,
	
		-- Signals to SWIR sensor
        sensor_reset_even   =>	sensor_reset_even,
		sensor_reset_odd    =>	sensor_reset_odd,
		Cf_select1			=>	Cf_select1,
		Cf_select1			=>	Cf_select2,
		AD_sp_even			=>	AD_sp_even,
		AD_sp_odd			=>	AD_sp_odd,
		AD_trig_even		=>	AD_trig_even,
		AD_trig_odd			=>	AD_trig_odd
    );

	adc_control_circuit : component swir_adc
	port map (
        clock_adc			=>	sck,
		clock_main			=>	clock,
		reset_n     		=>	reset_n,
        
		output_done			=>	adc_done,
        
		adc_trigger			=>	sensor_adc_trigger,
		adc_start			=>	sensor_adc_start,
		
		sdi					=>	sdi,
		cnv					=>	cnv,
		sdo					=>	sdo,
		
		fifo_rdreq			=>	adc_fifo_rd,
		fifo_rdempty		=>	adc_fifo_empty,
		fifo_data_read		=>	pixel
	);

	-- Synchronize reset
	process(clock) is
	begin
		if rising_edge(clock) then
			reset_n1			<=	reset_n;
			reset_n2			<=	reset_n1;
			reset_n3 			<=	reset_n2;
		end if;
	end process;
	
	-- Hold reset for 600 clock cycles to be registered by other clock domains
	process(clock) is
		if rising_edge(clock) then
			if reset_counter = 600 then
				reset_counter <= (others => '0');
			elsif reset_n2 = '0' and reset_n3 = '1' then
				reset_counter <= (others => '0');
			elsif reset_n3 = '0' or reset_counter > 0 then
				reset_counter <= reset_counter + 1;
			end if;
		end if;
	end process;
	
	reset_n_synchronous <= '0' if reset_counter < 600 else '1';
	
	-- Get stable signals from signals which cross clock domains
	process(clock) is
	begin
		if rising_edge(clock) then
			
			sensor_done1		<= sensor_done;
			sensor_done2		<= sensor_done1;
			sensor_done3		<= sensor_done2;
			
			-- Register rising edge of signals
			if (sensor_done3 = '0' and sensor_done2 = '1') then
				sensor_done_local <= '1';
			else
				sensor_done_local <= '0';
			end if;
		end if;
	end process;
	
	process(clock) is
	begin
		if rising_edge(clock) then
			output_done1		<= output_done;
			output_done2		<= output_done1;
			output_done3		<= output_done2;
			
			-- Register rising edge of signals
			if (output_done3 = '0' and output_done2 = '1') then
				output_done_local <= '1';
			else
				output_done_local <= '0';
			end if;
		end if;
	end process;
	
	
	-- Process to stretch sensor_begin signal to send to swir clock domain
	-- Assuming worst case lowest swir domain clock speed of 100 kHz
	process(clock, reset_n)
	begin
		if reset_n = '0' then
			counter_sensor_begin <= 0;
		elsif rising_edge(clock) then
			if sensor_begin_local = '1' then
				counter_sensor_begin <= 1001;
			elsif counter_sensor_begin > 0 then
				counter_sensor_begin <= counter_sensor_begin - 1;
			end if;
		end if;
	end process;

	-- Register configuration signals
	process(clock, reset_n)
	begin
		if rising_edge(clock) then
			if config.start_config = '1' then
				clcoks_per_frame_temp <= config.frame_clocks;
				clocks_per_exposure_temp <= config.exposure_clocks;
				number_of_rows_temp <= config.length;
			end if;
		end if;
	end process;
	
	-- Only update configuration signals if sensor is not in the middle of imaging
	-- Configuration signals ideally set only with accomanpying reset
	process(clock, reset_n)
	begin
		if reset_n = '0' then
			number_of_rows <= 0;
		if rising_edge(clock) then
			if row_counter = 0 then
				clocks_per_frame <= clocks_per_frame_temp;
				clocks_per_exposure <= clocks_per_exposure_temp;
				number_of_rows <= number_of_rows_temp;
			end if;
		end if;
	end process;
	
	-- Count number of rows that have been imaged, and trigger imaging of row
	process(clock, reset_n)
	begin
		if reset_n = '0' then
			row_counter <= (others=>'0');
			sensor_begin_local <= '0';
		elsif rising_edge(clock) then
			if (do_imaging = '1' and row_counter = '0') or (sensor_done_local = '1' and row_counter < number_of_rows) then
				row_counter <= row_counter + 1;
				sensor_begin_local <= '1';
			elsif row_counter = number_of_rows then
				row_counter <= (others=>'0');
				sensor_begin_local <= '0';
			else
				sensor_begin_local <= '0';
			end if;
		end if;
	end process;
	
	-- Reading of data from FIFO
	fifo_rdreq <= '1' when output_done_local = '1' and fifo_rdempty = '0' else '0';
	pixel_available <= ''1' when fifo_rdreq = '1' else '0';
	
	-- Sensor conversion efficiency - 0 (low) or 1 (high)
	sensor_ce <= '1';

	-- Stretched version of sensor_begin_local for swir domain
	sensor_begin <= '1' when counter_sensor_begin > 0 else '0';
	
	-- Create clocks going to swir sensor
	sensor_clock_even <= sensor_clock;
	sensor_clock_even <= not sensor_clock;
	
	sensor_integration <= clocks_per_exposure / 64;
	
	-- stretch integration_time?
	
	
	-- Set voltage -> put it in ff for hold time?
	SWIR_4V0 <= '1' when reset_n = '1' else '0';
	SWIR_1V2 <= '1' when reset_n = '1' else '0';
	
	reset <= not reset_n;
	
	-- Set reset of sensor
	
	
end architecture rtl;