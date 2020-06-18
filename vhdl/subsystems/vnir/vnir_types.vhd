----------------------------------------------------------------
--	
--	 Copyright (C) 2015  University of Alberta
--	
--	 This program is free software; you can redistribute it and/or
--	 modify it under the terms of the GNU General Public License
--	 as published by the Free Software Foundation; either version 2
--	 of the License, or (at your option) any later version.
--	
--	 This program is distributed in the hope that it will be useful,
--	 but WITHOUT ANY WARRANTY; without even the implied warranty of
--	 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--	 GNU General Public License for more details.
--	
--	
-- @file vnir_subsystem.vhd
-- @author Alexander Epp
-- @date 2020-06-16
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package vnir_types is
    type vnir_window_t is record
        lo  : integer range 0 to 2048-1;
        hi  : integer range 0 to 2048-1;
    end record vnir_window_t;

    type vnir_config_t is record
        window_1    : vnir_window_t;
        window_2    : vnir_window_t;
        window_3    : vnir_window_t;
        -- TODO: add other configuration parameters here, e.g. framerate.
    end record vnir_config_t;

    constant vnir_pixel_bits : integer := 12;
    constant vnir_row_width  : integer := 2048;
    subtype vnir_pixel_t is unsigned(0 to vnir_pixel_bits-1);
    type vnir_row_t is array(0 to vnir_row_width-1) of vnir_pixel_t;
end package vnir_types;
