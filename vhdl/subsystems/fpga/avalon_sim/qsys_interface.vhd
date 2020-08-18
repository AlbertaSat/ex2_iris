-- qsys_interface.vhd

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

entity qsys_interface is
	port (
		avalon_slave_write_n   : in  std_logic                     := '0';             -- avalon_slave.write_n
		avalon_slave_writedata : in  std_logic_vector(31 downto 0) := (others => '0'); --             .writedata
		conduit_end_avalon     : out std_logic_vector(31 downto 0);                    --  conduit_end.new_signal
		reset_n                : in  std_logic                     := '0';             --        reset.reset_n
		clock                  : in  std_logic                     := '0'             --        clock.clk
    );
end entity qsys_interface;

architecture rtl of qsys_interface is

begin

conduit_end_avalon <= avalon_slave_writedata;	
	
end architecture rtl; -- of new_component