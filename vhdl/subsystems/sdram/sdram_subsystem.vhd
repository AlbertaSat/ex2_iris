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
-- @file sdram_subsystem.vhd
-- @author Alexander Epp
-- @date 2020-06-16
----------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.avalonmm_types.all;
use work.sdram_types.all;
use work.vnir_types.all;
use work.swir_types.all;
use work.fpga_types.all;


entity sdram_subsystem is
    port (
        clock               : in std_logic;
        reset_n             : in std_logic;

        vnir_rows_available : in std_logic;
        vnir_rows           : in vnir_rows_t;
        
        swir_row_available  : in std_logic;
        swir_row            : in swir_row_t;
        
        timestamp           : in timestamp_t;
        mpu_memory_change   : in std_logic;
        sdram_config         : in sdram_config_t;
        sdram_config_done    : out std_logic;
        sdram_busy           : out std_logic;
        sdram_error          : out std_logic;
        sdram_full           : out std_logic;
        
        sdram_avalon_out     : out avalonmm_rw_from_master_t;
        sdram_avalon_in      : in avalonmm_rw_to_master_t
    );
end entity sdram_subsystem;
