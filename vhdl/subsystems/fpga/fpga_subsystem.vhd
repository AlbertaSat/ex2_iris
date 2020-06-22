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

use work.vnir_types.all;  -- Gives outputs to the VNIR subsystem
use work.swir_types.all;  -- Gives outputs from SWIR subsystem
use work.ddr3_types.all;  -- Gives outptu to DDR3 subsystem
use work.fpga_types.all;  -- For timestamp_t


entity fpga_subsystem is
    port (
        clock               : in std_logic;
        reset_n             : in std_logic;
        
        vnir_config         : out vnir_config_t;
        vnir_config_done    : in std_logic;
        swir_config         : out swir_config_t;
        swir_config_done    : in std_logic;
        ddr3_config         : out ddr3_config_t;
        ddr3_config_done    : in std_logic;

        do_imaging          : out std_logic;
        
        timestamp           : out timestamp_t;
        init_timestamp      : in timestamp_t;

        image_request       : in std_logic;
        image_time          : in unsigned

        -- TODO: insert more here
    );
end entity fpga_subsystem;
