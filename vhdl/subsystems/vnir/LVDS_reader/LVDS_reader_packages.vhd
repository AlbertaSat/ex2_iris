library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package LVDS_data_array_pkg is
	type t_lvds_data_array is array(natural range <>) of std_logic_vector;
end package;