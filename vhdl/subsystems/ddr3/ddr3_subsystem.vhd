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

use work.vnir_types.all;  -- Accept inputs from VNIR subsystem
use work.swir_types.all;  -- Accept inputs from SWIR subsystem
use work.fpga_types.all;  -- Accept inputs from FPGA subsystem

-- @brief
--	 DDR3 SDRAM subsystem top-level entity
-- 
-- @details
--	 Top-level entity for the DDR3 SDRAM subsystem. Interfaces with the
--   VNIR and SWIR subsystems, the FPGA subsystem, and the DDR3 SDRAM
--   itself.
--
-- @attention
--	 Not implemented yet.
--
--
-- @param[in] clock (std_logic)
--      Main input system clock
-- @param[in] reset_n (std_logic)
--      Active-low synchronous reset.
--
-- @param[in] vnir_row_available (std_logic)
--      Asserted when a VNIR row is available to be read
-- @param[in] vnir_row_1 (vnir_row_t)
--      VNIR 440-480 nm row
-- @param[in] vnir_row_2 (vnir_row_t)
--      VNIR 840-880 nm row
-- @param[in] vnir_row_3 (vnir_row_t)
--      VNIR 620-670 nm row
-- 
-- @param[in] swir_row_available (std_logic)
--      Asserted when a SWIR row is available to be read
-- @param[in] swir_row (swir_row_t)
--      SWIR row
--
-- @param[in] timestamp (timestamp_t)
--      Timestamp matching the first row request
-- @param[in] mpu_memory_change (std_logic)
--      Notifies subsystem that the microprocessor has modified
--      the SDRAM contents.
-- @param[in] ddr3_config (ddr3_config_t)
--      DDR3 configuration parameters
-- @param[out] ddr3_config_done (std_logic)
--      Indicates the subsystem is finished configuring the SDRAM
-- @param[out] ddr3_full (std_logic)
--      Indicates that the SDRAM is full and cannot be written to
-- @param[out] ddr3_busy (std_logic)
--      Indicates the SDRAM is in use and shouldn't be modified
--      by the microcontroller.
--
-- @param[out] write_address (std_logic_vector(29 downto 0))
-- @param[out] write_burstcount (std_logic_vector(7 downto 0))
-- @param[in] write_waitrequest (std_logic)
-- @param[out] write_writedata (std_logic_vector(31 downto 0))
-- @param[out] write_byteenable (std_logic_vector(3 downto 0))
-- @param[out] write_write (std_logic)
--
-- @param[out] read_address (std_logic_vector(29 downto 0))
-- @param[out] read_burstcount (std_logic_vector(7 downto 0))
-- @param[in] read_waitrequest (std_logic)
-- @param[in] read_readdata (std_logic_vector(31 downto 0))
-- @param[in] read_readdatavalid (std_logic)
-- @param[out] read_read (std_logic)
entity ddr3_subsystem is
    port (
        clock               : in std_logic;
        reset_n             : in std_logic;
        vnir_row_available  : in std_logic;
        vnir_row_1          : in vnir_row_t;
        vnir_row_2          : in vnir_row_t;
        vnir_row_3          : in vnir_row_t;
        swir_row_available  : in std_logic;
        swir_row            : in swir_row_t;
        timestamp           : in timestamp_t;
        mpu_memory_change   : in std_logic;
        ddr3_config         : in ddr3_config_t;
        ddr3_config_done    : out std_logic;
        ddr3_full           : out std_logic;
        ddr3_busy           : out std_logic;
        write_address       : out std_logic_vector(29 downto 0);
        write_burstcount    : out std_logic_vector(7 dowto 0);
        write_waitrequest   : in std_logic;
        write_writedata     : out std_logic_vector(31 downto 0);
        write_byteenable    : out std_logic_vector(3 downto 0);
        write_write         : out std_logic;
        read_address        : out std_logic_vector(29 downto 0);
        read_burstcount     : out std_logic_vector(7 downto 0);
        read_waitrequest    : in std_logic;
        read_readdata       : in std_logic_vector(31 downto 0);
        read_readdatavalid  : in std_logic;
        read_read           : out std_logic;
    );
end entity ddr3_subsystem;
