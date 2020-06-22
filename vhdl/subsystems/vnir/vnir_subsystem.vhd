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

use work.spi_types.all;
use work.sensor_comm_types.all;
use work.vnir_types.all;


entity vnir_subsystem is
    port (
        clock           : in std_logic;
        reset_n         : in std_logic;

        config          : in vnir_config_t;
        config_done     : out std_logic;
        
        do_imaging      : in std_logic;

        rows            : out vnir_rows_t;
        rows_available  : out std_logic;
        
        sensor_clock    : out std_logic;
        sensor_reset    : out std_logic;
        
        spi_out         : out spi_from_master_t;
        spi_in          : in spi_to_master_t;
        
        frame_request   : out std_logic;
        lvds            : in vnir_lvds_t
    );
end entity vnir_subsystem;
