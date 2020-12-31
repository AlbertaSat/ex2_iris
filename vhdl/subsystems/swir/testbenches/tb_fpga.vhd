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
	constant ClockPeriod 			:	time := 1000 ms / ClockFrequency; -- 20 ns
	
	signal fpga_clock_internal		:	std_logic := '0';
	
begin
	
	-- Process for generating the clock
	fpga_clock_internal <=	not fpga_clock_internal after ClockPeriod/2;
	fpga_clock			<=	fpga_clock_internal;
	
	-- Randomly and asynchronously reset the system during imaging
	process is
	begin
		-- Take the DUT out of reset
		reset_n <= '1';
		
		wait for 13 ns;
		reset_n <= '0';
		wait for 77 ns;
		reset_n <= '1';
		
		wait;
	end process;
	
	-- Testbench sequence
	process is
	begin
		do_imaging <= '0';
		arbitrary_wait : for k in 0 to 150 loop
			wait until rising_edge(fpga_clock_internal);
		end loop arbitrary_wait;
		
		do_imaging <= '1';
		wait until rising_edge(fpga_clock_internal);
		do_imaging <= '0';

		wait;
	end process;
	
	-- Set configuration signals
	process is
	begin
		arbitrary_wait : for k in 0 to 100 loop
			wait until rising_edge(fpga_clock_internal);
		end loop arbitrary_wait;
		
		config.frame_clocks <= 50000;
		config.exposure_clocks <= 64*6;
		config.length <= 5;
		wait until rising_edge(fpga_clock_internal);
		start_config <= '1';
		
		wait until rising_edge(fpga_clock_internal);
		start_config <= '0';
		wait;
	end process;
	
	-- Test voltage control
	process is
	begin
		control.volt_conv <= '1';
		wait until rising_edge(fpga_clock_internal);
		control.volt_conv <= '0';
		wait until rising_edge(fpga_clock_internal);
		
		wait;
	end process;
	
end architecture;