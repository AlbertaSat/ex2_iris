-- swir_subsystem.vhd

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

entity swir_subsystem is
	port (
		avalon_slave_write_n   : in std_logic                       := '0';             -- avalon_slave.write_n
		avalon_slave_writedata : in std_logic_vector(31 downto 0)  := (others => '0'); --             .writedata
		avalon_slave_read_n    : in std_logic                       := '0';             -- avalon_slave.read_n
		avalon_slave_readdata  : out std_logic_vector(31 downto 0) := (others => '0'); --             .readdata
		clock                  : in std_logic                       := '0';             --        clock.clk
		reset_n                : in std_logic                       := '0'              --        reset.reset_n
	);
end entity swir_subsystem;

architecture rtl of swir_subsystem is
begin

	-- TODO: Auto-generated HDL template

end architecture rtl; -- of swir_subsystem
