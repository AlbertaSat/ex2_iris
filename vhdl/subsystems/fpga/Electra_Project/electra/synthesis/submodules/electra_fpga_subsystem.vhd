-- electra_fpga_subsystem.vhd

-- This file was auto-generated as a prototype implementation of a module
-- created in component editor.  It ties off all outputs to ground and
-- ignores all inputs.  It needs to be edited to make it do something
-- useful.
-- 
-- This file will not be automatically regenerated.  You should check it in
-- to your version control system if you want to keep it.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity electra_fpga_subsystem is
	port (
		avalon_slave_write_n   : in  std_logic                     := '0';             -- avalon_slave.write_n
		avalon_slave_writedata : in  std_logic_vector(31 downto 0) := (others => '0'); --             .writedata
		avalon_slave_read_n    : in  std_logic                     := '0';             --             .read_n
		avalon_slave_readdata  : out std_logic_vector(31 downto 0);                    --             .readdata
		reset_n                : in  std_logic                     := '0';             --        reset.reset_n
		clock                  : in  std_logic                     := '0';             --        clock.clk
		conduit_end_data       : out std_logic_vector(31 downto 0)                     --  conduit_end.export
	);
end entity electra_fpga_subsystem;

architecture rtl of electra_fpga_subsystem is
begin

	-- TODO: Auto-generated HDL template

	avalon_slave_readdata <= "00000000000000000000000000000000";

	conduit_end_data <= "00000000000000000000000000000000";

end architecture rtl; -- of electra_fpga_subsystem
