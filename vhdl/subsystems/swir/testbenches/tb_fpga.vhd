library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.swir_types.all;

entity tb_fpga is
	 port (
		fpga_clock			: out std_logic		:= '1';
		reset_n         	: out std_logic		:= '0';
		
		do_imaging			: out std_logic;
		
		row             	: in swir_row_t;
        row_available   	: in std_logic
    );
end entity;

architecture sim of tb_fpga is

	constant ClockFrequency 		:	integer := 50e6; -- 50 MHz
	constant ClockPeriod 			:	time := 1000 ms / ClockFrequency; -- 20 ns
	
	signal fpga_clock_internal		:	std_logic;
	
begin
	
	--process for generating the clock
	fpga_clock_internal <=	not fpga_clock_internal after ClockPeriod/2;
	fpga_clock			<=	fpga_clock_internal;
	
	-- Testbench sequence
	
	process is
	begin
		-- After 40 ns, image for 2000 ns
		wait for 40 ns;
		do_imaging <= '1';
		wait for 2000 ns;
		do_imaging <= '0';

		wait;
	end process;
	
	-- Randomly and asynchronously reset the system during imaging
	process is
	begin
		-- Take the DUT out of reset
		reset_n <= '1';
		
		wait for 1007 ns;
		reset_n <= '0';
		wait for 77 ns;
		reset_n <= '1';
		
		wait;
	end process;
	
end architecture;