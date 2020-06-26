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
-- @file swir_subsystem.vhd
-- @author Alexander Epp
-- @date 2020-06-16
----------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.swir_types.all;


entity swir_subsystem is
    port (
        clock           : in std_logic;
        reset_n         : in std_logic;
        
        config          : in swir_config_t;
        control         : out swir_control_t;
        config_done     : out std_logic;
        
        do_imaging      : in std_logic;

        num_rows        : out integer;
        row             : out swir_row_t;
        row_available   : out std_logic;

        sensor_clock    : out std_logic;
        sensor_reset    : out std_logic
    );
end entity swir_subsystem;
