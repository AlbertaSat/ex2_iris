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
-- @file sdram_types.vhd
-- @author Alexander Epp
-- @date 2020-06-22
----------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package avalonmm_types is

    type avalonmm_write_from_master_t is record
        address     : std_logic_vector(29 downto 0);
        burst_count : std_logic_vector(7 downto 0);
        write_data  : std_logic_vector(31 downto 0);
        byte_enable : std_logic_vector(3 downto 0);
        write_cmd   : std_logic;
    end record avalonmm_write_from_master_t;

    type avalonmm_write_to_master_t is record
        wait_request : std_logic;
    end record avalonmm_write_to_master_t;

    type avalonmm_read_from_master_t is record
        address     : std_logic_vector(29 downto 0);
        burst_count : std_logic_vector(7 downto 0);
        read_cmd    : std_logic;
    end record avalonmm_read_from_master_t;

    type avalonmm_read_to_master_t is record
        wait_request    : std_logic;
        read_data       : std_logic_vector(31 downto 0);
        read_data_valid : std_logic;
    end record avalonmm_read_to_master_t;

    type avalonmm_write_t is record
        from_master : avalonmm_write_from_master_t;
        to_master   : avalonmm_write_to_master_t;
    end record avalonmm_write_t;

    type avalonmm_read_t is record
        from_master : avalonmm_read_from_master_t;
        to_master   : avalonmm_read_to_master_t;
    end record avalonmm_read_t;

    type avalonmm_rw_from_master_t is record
        r : avalonmm_read_from_master_t;
        w : avalonmm_write_from_master_t;
    end record avalonmm_rw_from_master_t;

    type avalonmm_rw_to_master_t is record
        r : avalonmm_read_to_master_t;
        w : avalonmm_write_to_master_t;
    end record avalonmm_rw_to_master_t;

    type avalonmm_rw_t is record
        from_master : avalonmm_rw_from_master_t;
        to_master   : avalonmm_rw_to_master_t;
    end record avalonmm_rw_t;

end package avalonmm_types;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package spi_types is

    type spi_from_master_t is record
        clock        : std_logic;
        slave_select : std_logic;
        data         : std_logic;
    end record spi_from_master_t;

    type spi_to_master_t is record
        data : std_logic;
    end record spi_to_master_t;

    type spi_t is record
        from_master : spi_from_master_t;
        to_master   : spi_to_master_t;
    end record spi_t;

end package spi_types;