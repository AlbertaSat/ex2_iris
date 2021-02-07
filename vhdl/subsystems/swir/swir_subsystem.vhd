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

-- Check stability time of sensor after powerup
-- bound integers
-- set conversion efficiency
-- Actually, want to subtract integration time from total time and round to closest multiple of 64
-- set clocks per frame initial value
-- fix frame clocks
-- stretch integration_time?
-- max frame clocks?
-- frame clocks standard value
-- from SWIR_adc.vhd: Note: Should maintain one clock cycle of sck between conversion to allow for sdi to go high

-- Startup sequence: reset, obtain config

-- This circuit controls a short-wave infrared (SWIR) sensor and its analog-to-digital converter (ADC)
-- When triggered by the top-level "FPGA subsystem", this circuit (the "SWIR subsystem") will image n rows of SWIR data given 
--		certain configuration specifications, and send the data to the "SDRAM subsystem" to be written to SDRAM
-- The SWIR sensor is the 1x512 pixel G11508 Hamamatsu sensor
-- Data from the SWIR sensor is sent to an ADAQ7980 ADC, in 4-wire CS mode with busy indicator, with VIO over 1.7 V
-- Voltage to the SWIR sensor is controlled by two voltage regulators: TPS73601DCQR (1V2) and TPS62821DLCR (4V0)

-- swir_subsystem.vhd is the top level code of SWIR subsystem, and does the following
--		Manages signals from FPGA and SDRAM subsystems into SWIR subsystem, and prepares signal for crossing clock domains
--		Reads configuration signals from FPGA subsystem, and passes on integration time to SWIR sensor control circuit
--		Triggers SWIR sensor control circuit to image rows
--		Instantiates PLL IP to create SWIR and ADC clocks
--		Read data out of FIFO buffer to SDRAM subsystem
--		Control enable signals to voltage regulators
--		Instantiates swir_sensor.vhd, which controls signals directly to SWIR sensor, and may image 1 row if triggered
--		Instantiates swir_adc.vhd, which controls signals to ADC and writes data from ADC to FIFO buffer

-- Signals:
--		clock: 			50 MHz FPGA clock
--		reset_n: 		input asynchronous reset from FPGA subsystem
--
--		start_config: 	[Pulse] Configuration signals are registered on this pulse
--		config_done: 	[Pulse] Indicates current configuration signals are being used. If configuration signals are set
--								while sensor is imaging, they will not be used until imaging is done (n rows are finished)
--		config: 		Configuration signals. Consists of:
--			config.frame_clocks: 	Integer, sets number of 50 MHz clock cycles per frame (one frame indicates length between subsequent sensor integrations)
--			config.exposure_clocks: Integer, sets number of clock cycles for sensor to integrate over (multiple of 64)
--			config.length: 			Integer, number of rows to image (512 pixels per row, one frame per row)
--		control:		Control signals. Consists of:
--			control.volt_conv: 		Sets enable signal (active high) for voltage regulators
--
--		do_imaging: 	[Pulse] Starts imaging process given current configuration settings (triggers imaging of n rows)
--		pixel_available:[Pulse] Indicates one pixel of data is valid to be read by SDRAM subsystem
--		pixel: 			16 bit logic array containing data for one pixel
--		
--		sdi:			Serial Data Input. Control signal for ADC (refer to ADAQ7980 datasheet)
--		sdo:			Serial Data Output. Digital data outputted on sdo (refer to ADAQ7980 datasheet)
--		sck:			Serial Data Clock Input. Serial Data is clocked out according to speed of sck
--		cnv:			Convert Input. Control signal for ADC (refer to ADAQ7980 datasheet)
--
--		sensor_clock_even:	Clock sent to SWIR sensor, and controls speed of analog data outputted
--		sensor_clock_odd:	Clock sent to SWIR sensor, and controls speed of analog data outputted
--		sensor_reset_even:	Control signal sent to SWIR sensor, controls integration time
--		sensor_reset_odd:	Control signal sent to SWIR sensor, controls integration time
--		Cf_select1:			Control signal sent to SWIR sensor, controls conversion efficiency of sensor (high or low)
--		Cf_select2:			Control signal sent to SWIR sensor, controls conversion efficiency of sensor (high or low)
--		AD_sp_even:			Pulse sent from SWIR sensor, indicates data is about to be read out
--		AD_sp_odd:			Pulse sent from SWIR sensor, indicates data is about to be read out
--		AD_trig_even:		Signal sent from SWIR sensor, not used
--		AD_trig_odd:		Signal sent from SWIR sensor, not used
--
--		SWIR_4V0:			Enable signal for TPS62821DLCR voltage regulator
--		SWIR_1V2:			Enable signal for TPS73601DCQR voltage regulator

-- Constraints:
--		config.frame_clocks: 
--		config.exposure_clocks: 64 - 17856 inclusive. Must be a multiple of 64
--		config.length: 1 - 1023 inclusive


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.swir_types.all;


entity swir_subsystem is
    port (
        clock           	: in std_logic;
        reset_n         	: in std_logic;
		
		start_config		: in std_logic;
		config_done			: out std_logic;
        config          	: in swir_config_t;
        control         	: in swir_control_t;
		
        do_imaging      	: in std_logic;
	
		-- Signals to SDRAM subsystem
        pixel           	: out swir_pixel_t;
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
        
        integration_time    : in unsigned(9 downto 0);
		
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
	signal sensor_integration	: unsigned(9 downto 0);
	signal sensor_ce			: std_logic;
	signal sensor_begin			: std_logic;
	signal sensor_done			: std_logic;
	signal sensor_adc_trigger	: std_logic;
	signal sensor_adc_start		: std_logic;
	
	signal adc_clock			: std_logic;
	signal adc_done				: std_logic;
	signal adc_fifo_rd			: std_logic;
	signal adc_fifo_empty		: std_logic;
	signal read_counter			: unsigned(7 downto 0);
	
	signal row_counter			: unsigned(9 downto 0);
	signal clocks_per_frame_temp : integer range -1 to 100000;
	signal clocks_per_frame		: integer range -1 to 100000;
	signal clocks_per_exposure_temp	: integer range 0 to 17920;
	signal clocks_per_exposure	: integer range 0 to 17920;
	signal number_of_rows_temp	: integer range 0 to 5000;
	signal number_of_rows		: integer range 0 to 5000;
	signal config_wait			: std_logic;
	
	signal counter_sensor_begin : integer range 0 to 1001;
	signal sensor_begin_local	: std_logic;
	
	signal frame_counter		: unsigned(16 downto 0);
	signal in_frame				: std_logic;
	signal min_one_frame_len	: integer range 0 to 100000; -- Minimum number of 50 MHz clock cycles in one frame (based on readout time and min integration time)
	
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
	signal circuit_on			: std_logic;
	
	signal reset				: std_logic;
	signal pll_locked			: std_logic;
	
	signal pixel_vector			: std_logic_vector(15 downto 0);
	
	constant hold_time			: integer := 70;
	
begin	
	
	-- PLL details: 50 MHz reference clock frequency, Integer-N PLL in direct mode
	-- M = 14, N = 1
	-- Counter 0 (cascade counter into counter 2): C = 32; Counter 1: C = 28; Counter 2: C = 16
	-- No phase shifts, 50% duty cycles
	pll_inst : component pll_0002
	port map (
		refclk   => clock,   		-- 50 MHz input frequency
		rst      => reset,			-- asynchronous reset
		outclk_1 => sensor_clock,	-- 0.78125 MHz SWIR sensor clock
		outclk_2 => adc_clock,		-- 43.75 MHz ADC clock
		locked   => pll_locked,		-- Signal goes high if locked
		outclk_0 => open			-- Terminated (used as cascade counter)
	);
	
	sck <= adc_clock;
	
	sensor_control_circuit : component swir_sensor
    port map (
        clock_swir      	=>	sensor_clock,
        reset_n         	=>  reset_n_synchronous,
        
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
		Cf_select2			=>	Cf_select2,
		AD_sp_even			=>	AD_sp_even,
		AD_sp_odd			=>	AD_sp_odd,
		AD_trig_even		=>	AD_trig_even,
		AD_trig_odd			=>	AD_trig_odd
    );

	adc_control_circuit : component swir_adc
	port map (
        clock_adc			=>	adc_clock,
		clock_main			=>	clock,
		reset_n     		=>	reset_n_synchronous,
        
		output_done			=>	adc_done,
        
		adc_trigger			=>	sensor_adc_trigger,
		adc_start			=>	sensor_adc_start,
		
		sdi					=>	sdi,
		cnv					=>	cnv,
		sdo					=>	sdo,
		
		fifo_rdreq			=>	adc_fifo_rd,
		fifo_rdempty		=>	adc_fifo_empty,
		fifo_data_read		=>	pixel_vector
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
	
	-- Hold reset for 'hold_time' clock cycles to be registered by other clock domains
	-- hold_time is at least 65 (50 MHz FPGA clock speed / 0.78125 MHz SWIR clock speed [slowest clock] + 1)
	process(clock) is
	begin
		if rising_edge(clock) then
			if reset_counter = hold_time then
				reset_counter <= (others => '0');
			elsif reset_n2 = '0' and reset_n3 = '1' then
				reset_counter <= (others => '0');
			elsif reset_n3 = '0' or reset_counter > 0 then
				reset_counter <= reset_counter + 1;
			end if;
		end if;
	end process;
	
	-- Keep reset if fpga sends reset signal, or if pll is not yet locked
	reset_n_synchronous <= '0' when (reset_counter < hold_time and reset_counter > 0) or (circuit_on /= '1') else '1';
	
	-- Get stable signals from signals which cross clock domains
	-- Sensor_done indicates SWIR sensor has imaged one row
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
	
	-- output_done indicates ADC has output serial data for one pixel
	process(clock) is
	begin
		if rising_edge(clock) then
			output_done1		<= adc_done;
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
	
	-- Process to stretch sensor_begin signal to send to swir clock domain of 0.78125 MHz
	process(clock, reset_n, circuit_on)
	begin
		if reset_n = '0' or circuit_on /= '1' then
			counter_sensor_begin <= 0;
		elsif rising_edge(clock) then
			if sensor_begin_local = '1' then
				counter_sensor_begin <= hold_time;
			elsif counter_sensor_begin > 0 then
				counter_sensor_begin <= counter_sensor_begin - 1;
			end if;
		end if;
	end process;

	-- Register configuration signals
	process(clock, reset_n, circuit_on)
	begin
		if reset_n = '0' or circuit_on /= '1' then
			number_of_rows_temp <= 0;
			clocks_per_frame_temp <= -1;
			clocks_per_exposure_temp <= 64;
		elsif rising_edge(clock) then
			if start_config = '1' then
				clocks_per_frame_temp <= config.frame_clocks;
				clocks_per_exposure_temp <= config.exposure_clocks;
				number_of_rows_temp <= config.length;	
			end if;
		end if;
	end process;
	
	-- Only update configuration signals if sensor is not in the middle of imaging
	-- Configuration signals ideally set only with accompanying reset
	process(clock, reset_n, circuit_on)
	begin
		if reset_n = '0' or circuit_on /= '1' then
			number_of_rows <= 0;
			clocks_per_frame <= -1;
			clocks_per_exposure <= 64;
		elsif rising_edge(clock) then
			if row_counter = 0 then
				clocks_per_frame <= clocks_per_frame_temp;
				clocks_per_exposure <= clocks_per_exposure_temp;
				number_of_rows <= number_of_rows_temp;
			end if;
		end if;
	end process;
	
	-- Process to set config_done signal
	-- Which is a 1 clock cycle pulse set when a new configuration has been registered
	process(clock, reset_n, circuit_on)
	begin
		if reset_n = '0' or circuit_on /= '1' then
			config_done <= '0';
			config_wait <= '0';
		elsif rising_edge(clock) then
			if start_config = '1' and row_counter = 0 then
				config_done <= '1';
				config_wait <= '0';
			elsif start_config = '1' then  -- If configuration is during imaging
				config_done <= '0';
				config_wait <= '1';
				-- config_wait indicates a new configuration has been sent but the imager is
				--   in the middle of imaging and did not register the new settings
			elsif config_wait = '1' and row_counter = 0 then  -- If configuration is being registered after imaging is done
				config_done <= '1';
				config_wait <= '0';
			else
				config_done <= '0';
			end if;
		end if;
	end process;
	
	-- Count number of rows that have been imaged, and trigger imaging of row
	process(clock, reset_n, circuit_on)
	begin
		if reset_n = '0' or circuit_on /= '1' then
			sensor_begin_local <= '0';
		elsif rising_edge(clock) then
			-- If do_imaging is triggered to image the first row, or if nth row is about to be imaged
			--  Add row_counter = 0 condition to ensure do_imaging isn't triggered while imaging is in progress
			if (do_imaging = '1' and row_counter = 0) or (in_frame = '0' and row_counter < number_of_rows and row_counter > 0) then
				sensor_begin_local <= '1';
			else
				sensor_begin_local <= '0';
			end if;
		end if;
	end process;
	
	-- in_frame tracks whether the sensor is in the process of integrating or readout
	process(clock, reset_n, circuit_on)
	begin
		if reset_n = '0' or circuit_on /= '1' then
			in_frame <= '0';
		elsif rising_edge(clock) then
			if sensor_begin_local = '1' then
				in_frame <= '1';
			elsif frame_counter = 0 then
				in_frame <= '0';
			else
				in_frame <= in_frame;
			end if;
		end if;
	end process;
	
	-- frame_counter counts the number of FPGA clock cycles in each frame
	--   to ensure that it is within configuration settings
	process(clock, reset_n, circuit_on)
	begin
		if reset_n = '0' or circuit_on /= '1' then
			frame_counter <= (others=>'0');
		elsif rising_edge(clock) then
			if sensor_begin_local = '1' then  -- start counter
				frame_counter <= (others=>'0');
				frame_counter <= frame_counter + 1;
			-- Reset counter if sensor_done signal is triggered while frame_counter is at least equal to configuration setting
			--  or, if frame_counter is at least equal to configuration setting while still being greater than the minimum frame length
			elsif ((sensor_done_local = '1' and frame_counter >= clocks_per_frame) 
				or (frame_counter >= clocks_per_frame and frame_counter >= min_one_frame_len)) then
				frame_counter <= (others=>'0');
			elsif frame_counter > 0 then
				frame_counter <= frame_counter + 1;
			else
				frame_counter <= (others=>'0');
			end if;
		end if;
	end process;
	
	-- row_counter keeps track of amount of rows imaged to conform to configuration setting
	process(clock, reset_n, circuit_on)
	begin
		if reset_n = '0' or circuit_on /= '1' then
			row_counter <= (others=>'0');
		elsif rising_edge(clock) then
			--if do_imaging = '1' and row_counter = 0 then -- reset row_counter 
			--	row_counter <= (others=>'0');
			if frame_counter = 1 then -- frame_counter = 1 near the start of each row - use it to increment row_counter
				row_counter <= row_counter + 1;
			-- If row_counter equals configuration setting for number of rows to image, and the frame is done, reset the counter
			elsif row_counter = number_of_rows and ((sensor_done_local = '1' and frame_counter >= clocks_per_frame) 
				or (frame_counter >= clocks_per_frame and frame_counter >= min_one_frame_len)) then
				row_counter <= (others=>'0');
			else
				row_counter <= row_counter;
			end if;
		end if;
	end process;
	
	-- Count number of data writes to FIFO to be read out
	process(clock, reset_n, circuit_on)
	begin
		if reset_n = '0' or circuit_on /= '1' then
			read_counter <= (others => '0');
		elsif rising_edge(clock) then
			if read_counter > 0 and adc_fifo_empty = '0' then
				read_counter <= read_counter - 1;
			end if;
			
			if output_done_local = '1' then
				read_counter <= read_counter + 1;
			elsif read_counter >= 128 then  -- FIFO width is 128
				read_counter <= (others => '0');
			end if;
		end if;
	end process;
	
	-- Read data out of FIFO
	process(clock, reset_n, circuit_on)
	begin
		if reset_n = '0' or circuit_on /= '1' then
			adc_fifo_rd <= '0';
			pixel_available <= '0';
		elsif rising_edge(clock) then
			if read_counter > 0 and adc_fifo_empty = '0' then
				adc_fifo_rd <= '1';
				pixel_available <= '1';
			else
				adc_fifo_rd <= '0';
				pixel_available <= '0';
			end if;
		end if;
	end process;
	
	-- Sensor conversion efficiency - 0 (low) or 1 (high)
	sensor_ce <= '1';

	-- Stretched version of sensor_begin_local for swir domain
	sensor_begin <= '1' when counter_sensor_begin > 0 else '0';
	
	-- Create clocks going to swir sensor
	sensor_clock_even <= sensor_clock;
	sensor_clock_odd <= not sensor_clock;
	
	-- Convert integration time in 50 Mhz clock cycles to 0.78125 MHz clock cycles
	--  and add 5 clock cycles for actual integration time setting (as shown in sensor datasheet)
	sensor_integration <= to_unsigned(clocks_per_exposure / 64, sensor_integration'length) + 5;
	
	-- Minimum length of one frame given a certain exposure period
	-- Refer to TX2-PL-124 for derivation of 35200 hard coded value
	min_one_frame_len <= 35200 + clocks_per_exposure;
	
	-- Set voltage
	SWIR_4V0 <= '1' when reset_n = '1' and control.volt_conv = '1' else '0';
	SWIR_1V2 <= '1' when reset_n = '1' and control.volt_conv = '1' else '0';
	
	-- Circuit_on indicates if voltage regulators and PLL are ready. If not, want to keep circuit in "reset" state
	circuit_on <= '1' when control.volt_conv = '1' and pll_locked =  '1' else '0';
	
	-- reset (active high) for PLL IP
	reset <= not reset_n;
	
	-- Convert array values to std_logic_vector values
	pixel(0) <= pixel_vector(0);
	pixel(1) <= pixel_vector(1);
	pixel(2) <= pixel_vector(2);
	pixel(3) <= pixel_vector(3);
	pixel(4) <= pixel_vector(4);
	pixel(5) <= pixel_vector(5);
	pixel(6) <= pixel_vector(6);
	pixel(7) <= pixel_vector(7);
	pixel(8) <= pixel_vector(8);
	pixel(9) <= pixel_vector(9);
	pixel(10) <= pixel_vector(10);
	pixel(11) <= pixel_vector(11);
	pixel(12) <= pixel_vector(12);
	pixel(13) <= pixel_vector(13);
	pixel(14) <= pixel_vector(14);
	pixel(15) <= pixel_vector(15);
	
	
end architecture rtl;