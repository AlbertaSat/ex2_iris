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
-- @file swir_types.vhd
-- @author Alexander Epp
-- @date 2020-06-16
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package swir_types is
    type swir_config_t is record
        -- TODO: add config values
    end record swir_config_t;

    constant swir_pixel_bits : integer := 0;  -- TODO: define this
    constant swir_row_width : integer := 512; -- TODO: define this
    subtype swir_pixel_t is unsigned(0 to swir_row_width-1);
    type swir_rot_t is array(0 to swir_row_width-1) of swir_pixel_t;
end package swir_types;
