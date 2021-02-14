library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.swir_types.all;

entity tb_fpga is
	 port (
		fpga_clock			: out std_logic		:= '1';
		reset_n         	: out std_logic		:= '0';
		
		start_config		: out std_logic		:= '0';
		config_done			: in std_logic;
		config          	: out swir_config_t;
        control         	: out swir_control_t;
		
		do_imaging			: out std_logic;
		
		-- To SDRAM subsystem
		pixel           	: in swir_pixel_t;
        pixel_available 	: in std_logic
    );
end entity;

architecture sim of tb_fpga is

	constant ClockFrequency 		:	integer := 50e6; -- 50 MHz
	constant ClockPeriodFPGA 			:	time := 1000 ms / ClockFrequency; -- 20 ns
	
	signal fpga_clock_internal		:	std_logic := '0';

	
	
	-- Test 1: Standard Test
	-- Monitor: clock, reset_n, sensor_clock_even, do_imaging, sensor_reset_even, AD_sp_even,
	-- sensor_begin, sensor_adc_start, sdi, sdo, sensor_done
	procedure test1(signal fpga_clock_internal_p : in std_logic;
					signal do_imaging_p : out std_logic;
					signal reset_n_p	: out std_logic;
					signal volt_conv_p : out std_logic;
					signal start_config_p	: out std_logic;
					signal frame_clocks_p	: out integer;
					signal exposure_clocks_p	: out integer;
					signal length_p	: out integer) is
		constant ClockPeriodADC			:	time := 23 ns;
		constant ClockPeriodSWIR		:	time := 1280 ns;
		constant ClockPeriod			:	time := 20 ns;
	begin
		-- Set voltage control signal
		volt_conv_p <= '1';
	
		do_imaging_p <= '0';
		
		-- Take the DUT out of reset
		reset_n_p <= '1';
		wait for 13 ns;
		reset_n_p <= '0';
		wait for 2500 ns;
		reset_n_p <= '1';
		
		-- Wait, and set configuration signals
		wait until rising_edge(fpga_clock_internal_p);
		wait for ClockPeriod*100;
		frame_clocks_p <= 50000;
		exposure_clocks_p <= 64*6;
		length_p <= 3;
		wait until rising_edge(fpga_clock_internal_p);
		start_config_p <= '1';
		wait until rising_edge(fpga_clock_internal_p);
		start_config_p <= '0';
		
		-- Set do_imaging signal
		wait for ClockPeriod*50;
		do_imaging_p <= '1';
		wait until rising_edge(fpga_clock_internal_p);
		do_imaging_p <= '0';
		
	end procedure;
	
	
	-- Test 2: Standard Test with back to back frames
	procedure test2(signal fpga_clock_internal_p : in std_logic;
					signal do_imaging_p : out std_logic;
					signal reset_n_p	: out std_logic;
					signal volt_conv_p : out std_logic;
					signal start_config_p	: out std_logic;
					signal frame_clocks_p	: out integer;
					signal exposure_clocks_p	: out integer;
					signal length_p	: out integer) is
		constant ClockPeriodADC			:	time := 23 ns;
		constant ClockPeriodSWIR		:	time := 1280 ns;
		constant ClockPeriod			:	time := 20 ns;
	begin
		-- Set voltage control signal
		volt_conv_p <= '1';
	
		do_imaging_p <= '0';
		
		-- Take the DUT out of reset
		reset_n_p <= '1';
		wait for 13 ns;
		reset_n_p <= '0';
		wait for 77 ns;
		reset_n_p <= '1';
		
		-- Wait, and set configuration signals
		wait until rising_edge(fpga_clock_internal_p);
		wait for ClockPeriod*100;
		frame_clocks_p <= -1;
		exposure_clocks_p <= 64*6;
		length_p <= 3;
		wait until rising_edge(fpga_clock_internal_p);
		start_config_p <= '1';
		wait until rising_edge(fpga_clock_internal_p);
		start_config_p <= '0';
		
		-- Set do_imaging signal
		wait for ClockPeriod*50;
		do_imaging_p <= '1';
		wait until rising_edge(fpga_clock_internal_p);
		do_imaging_p <= '0';
		
	end procedure;
	
	-- Test 3: Reset Test
	-- Inserting reset during operation and ensuring proper results
	procedure test3(signal fpga_clock_internal_p : in std_logic;
					signal do_imaging_p : out std_logic;
					signal reset_n_p	: out std_logic;
					signal volt_conv_p : out std_logic;
					signal start_config_p	: out std_logic;
					signal frame_clocks_p	: out integer;
					signal exposure_clocks_p	: out integer;
                    signal length_p	: out integer) is
		constant ClockPeriodADC			:	time := 23 ns;
		constant ClockPeriodSWIR		:	time := 1280 ns;
		constant ClockPeriod			:	time := 20 ns;
	begin
		-- Set voltage control signal
		volt_conv_p <= '1';
	
		do_imaging_p <= '0';
		
		-- Take the DUT out of reset
		reset_n_p <= '1';
		wait for 13 ns;
		reset_n_p <= '0';
		wait for 77 ns;
		reset_n_p <= '1';
		
		-- Wait, and set configuration signals
		wait until rising_edge(fpga_clock_internal_p);
		wait for ClockPeriod*100;
		frame_clocks_p <= -1;
		exposure_clocks_p <= 64*10;
		length_p <= 5;
		wait until rising_edge(fpga_clock_internal_p);
		start_config_p <= '1';
		wait until rising_edge(fpga_clock_internal_p);
		start_config_p <= '0';
		
		-- Set do_imaging signal
		wait for ClockPeriod*50;
		do_imaging_p <= '1';
		wait until rising_edge(fpga_clock_internal_p);
		do_imaging_p <= '0';
		
		-- TEST: Reset during readout
		wait for ClockPeriodSWIR*75;
		reset_n_p <= '0';
		wait until rising_edge(fpga_clock_internal_p);
		reset_n_p <= '1';
		
		-- Set do_imaging signal, after waiting set time as outlined in TX2-PL-124
		wait for ClockPeriod*(35200+10);
		do_imaging_p <= '1';
		wait until rising_edge(fpga_clock_internal_p);
		do_imaging_p <= '0';
	end procedure;
	
	-- Test 4: Configuration Test
	-- Changing configuration settings and seeing that they hold
	procedure test4(signal fpga_clock_internal_p : in std_logic;
	                signal do_imaging_p : out std_logic;
	                signal reset_n_p	: out std_logic;
	                signal volt_conv_p : out std_logic;
	                signal start_config_p	: out std_logic;
	                signal frame_clocks_p	: out integer;
	                signal exposure_clocks_p	: out integer;
	                signal length_p	: out integer) is
		constant ClockPeriodADC			:	time := 23 ns;
		constant ClockPeriodSWIR		:	time := 1280 ns;
		constant ClockPeriod			:	time := 20 ns;
	begin
		-- Set voltage control signal
		volt_conv_p <= '1';
	
		do_imaging_p <= '0';
		
		-- Take the DUT out of reset
		reset_n_p <= '1';
		wait for 13 ns;
		reset_n_p <= '0';
		wait for 77 ns;
		reset_n_p <= '1';
		
		-- Wait, and set configuration signals
		wait until rising_edge(fpga_clock_internal_p);
		wait for ClockPeriod*100;
		frame_clocks_p <= -1;
		exposure_clocks_p <= 64*6;
		length_p <= 2;
		wait until rising_edge(fpga_clock_internal_p);
		start_config_p <= '1';
		wait until rising_edge(fpga_clock_internal_p);
		start_config_p <= '0';
		
		-- Set do_imaging signal
		wait for ClockPeriod*50;
		do_imaging_p <= '1';
		wait until rising_edge(fpga_clock_internal_p);
		do_imaging_p <= '0';
		
		-- Reset configuration signals. But, this should not 
		-- take hold until the previous cycle is finished
		wait for ClockPeriod*50;
		wait until rising_edge(fpga_clock_internal_p);
		frame_clocks_p <= -1;
		exposure_clocks_p <= 64*9;
		length_p <= 1;
		wait until rising_edge(fpga_clock_internal_p);
		start_config_p <= '1';
		wait until rising_edge(fpga_clock_internal_p);
		start_config_p <= '0';
		
		-- Redo do_imaging signal to test that configuration signals have taken hold
		wait for ClockPeriod*71000; -- Imaging of frames will be done by this time
		wait until rising_edge(fpga_clock_internal_p);
		do_imaging_p <= '1';
		wait until rising_edge(fpga_clock_internal_p);
		do_imaging_p <= '0';
	end procedure;
	
	-- Test 5: do_imaging test
	-- Testing do_imaging during imaging; should do nothing
	procedure test5(signal fpga_clock_internal_p : in std_logic;
	                signal do_imaging_p : out std_logic;
	                signal reset_n_p	: out std_logic;
	                signal volt_conv_p : out std_logic;
	                signal start_config_p	: out std_logic;
	                signal frame_clocks_p	: out integer;
	                signal exposure_clocks_p	: out integer;
	                signal length_p	: out integer) is
		constant ClockPeriodADC			:	time := 23 ns;
		constant ClockPeriodSWIR		:	time := 1280 ns;
		constant ClockPeriod			:	time := 20 ns;
	begin
		-- Set voltage control signal
		volt_conv_p <= '1';
	
		do_imaging_p <= '0';
		
		-- Take the DUT out of reset
		reset_n_p <= '1';
		wait for 13 ns;
		reset_n_p <= '0';
		wait for 77 ns;
		reset_n_p <= '1';
		
		-- Wait, and set configuration signals
		wait until rising_edge(fpga_clock_internal_p);
		wait for ClockPeriod*100;
		frame_clocks_p <= -1;
		exposure_clocks_p <= 64*6;
		length_p <= 4;  -- 4 frames this time
		wait until rising_edge(fpga_clock_internal_p);
		start_config_p <= '1';
		wait until rising_edge(fpga_clock_internal_p);
		start_config_p <= '0';
		
		-- Set do_imaging signal
		wait for ClockPeriod*50;
		do_imaging_p <= '1';
		wait until rising_edge(fpga_clock_internal_p);
		do_imaging_p <= '0';
		
		-- Redo do_imaging signal to test that nothing happens
		wait for ClockPeriod*5000;
		do_imaging_p <= '1';
		wait until rising_edge(fpga_clock_internal_p);
		do_imaging_p <= '0';
	end procedure;
	
	-- Test 6: voltage_control
	-- Removing voltage regulator enable signal should act the same as a reset
	procedure test6(signal fpga_clock_internal_p : in std_logic;
	                signal do_imaging_p : out std_logic;
	                signal reset_n_p	: out std_logic;
	                signal volt_conv_p : out std_logic;
	                signal start_config_p	: out std_logic;
	                signal frame_clocks_p	: out integer;
	                signal exposure_clocks_p	: out integer;
	                signal length_p	: out integer) is
		constant ClockPeriodADC			:	time := 23 ns;
		constant ClockPeriodSWIR		:	time := 1280 ns;
		constant ClockPeriod			:	time := 20 ns;
	begin
		-- Set voltage control signal
		volt_conv_p <= '1';
	
		do_imaging_p <= '0';
		
		-- Take the DUT out of reset
		reset_n_p <= '1';
		wait for 13 ns;
		reset_n_p <= '0';
		wait for 77 ns;
		reset_n_p <= '1';
		
		-- Wait, and set configuration signals
		wait until rising_edge(fpga_clock_internal_p);
		wait for ClockPeriod*100;
		frame_clocks_p <= -1;
		exposure_clocks_p <= 64*6;
		length_p <= 2;
		wait until rising_edge(fpga_clock_internal_p);
		start_config_p <= '1';
		wait until rising_edge(fpga_clock_internal_p);
		start_config_p <= '0';
		
		-- Set do_imaging signal
		wait for ClockPeriod*50;
		do_imaging_p <= '1';
		wait until rising_edge(fpga_clock_internal_p);
		do_imaging_p <= '0';
		
		-- Set voltage enable signal to 0
		wait for ClockPeriodSWIR*50;
		volt_conv_p <= '0';
		wait for ClockPeriod*10;
		volt_conv_p <= '1';
		wait for ClockPeriod*10;
		
		-- Set do_imaging signal with new configuration signals
		wait until rising_edge(fpga_clock_internal_p);
		frame_clocks_p <= -1;
		exposure_clocks_p <= 64*8;
		length_p <= 1;
		wait until rising_edge(fpga_clock_internal_p);
		start_config_p <= '1';
		wait until rising_edge(fpga_clock_internal_p);
		start_config_p <= '0';
		-- wait until rising_edge (config_done); -- Configuration will automaticalley be registered since it will not be imaging
		wait until rising_edge(fpga_clock_internal_p);
		do_imaging_p <= '1';
		wait until rising_edge(fpga_clock_internal_p);
		do_imaging_p <= '0';
		
	end procedure;
	
begin
	
	-- Process for generating the clock
	fpga_clock_internal <=	not fpga_clock_internal after ClockPeriodFPGA/2;
	fpga_clock			<=	fpga_clock_internal;
	
	process is
	begin
		-- Run one test at a time, comment out the rest
		-- Important signals to monitor from main_circuit:
		-- add wave clock reset_n sck sensor_clock_even do_imaging sensor_reset_even AD_sp_even sensor_begin sensor_adc_start sdi sdo sensor_done row_counter in_frame
		
		test1(fpga_clock_internal, do_imaging, reset_n, control.volt_conv, start_config, config.frame_clocks, config.exposure_clocks, config.length);
		-- test2(fpga_clock_internal, do_imaging, reset_n, control.volt_conv, start_config, config.frame_clocks, config.exposure_clocks, config.length);
		-- test3(fpga_clock_internal, do_imaging, reset_n, control.volt_conv, start_config, config.frame_clocks, config.exposure_clocks, config.length);
		-- test4(fpga_clock_internal, do_imaging, reset_n, control.volt_conv, start_config, config.frame_clocks, config.exposure_clocks, config.length);
		-- test5(fpga_clock_internal, do_imaging, reset_n, control.volt_conv, start_config, config.frame_clocks, config.exposure_clocks, config.length);
		-- test6(fpga_clock_internal, do_imaging, reset_n, control.volt_conv, start_config, config.frame_clocks, config.exposure_clocks, config.length);
		
		wait;
	end process;
		
end architecture;