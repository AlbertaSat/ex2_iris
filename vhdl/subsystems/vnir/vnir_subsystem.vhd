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

use work.vnir_types.all;

-- @brief
--	 VNIR subsystem top-level entity
-- 
-- @details
--	 Top-level entity for the VNIR subsystem. Interfaces with the VNIR
--   sensor, the fpga subsystem, and the ddr3 subsystem.
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
-- @param[in] vnir_config (vnir_config_t)
--      VNIR configuration parameters
-- @param[out] config_done (std_logic)
--      Held low while cofiguring
--
-- @param[out] row_available (std_logic)
--      Asserted when a row is ready to be read off of the row outputs
-- @param[out] row_1 (vnir_row_t)
--      440-480 nm row
-- @param[out] row_2 (vnir_row_t)
--      840-880 nm row
-- @param[out] row_3 (vnir_row_t)
--      620-670 nm row
--
-- @param[out] sensor_clock (std_logic)
--      Clock output to sensor
-- @param[out] sensor_reset (std_logic)
--      Reset sensor
-- @param[out] spi_clock (std_logic)
-- 		SPI output clock for data transfer synchronization
-- @param[in] spi_miso (std_logic)
-- 		SPI master-in, slave-out 
-- @param[out] spi_ss (std_logic)
-- 		active-high SPI slave-select line
-- @param[out] spi_mosi (std_logic)
-- 		SPI master-out, slave-in
-- @param[out] frame_request (std_logic)
--      Request frame from vnir sensor
-- @param[in] lvds_clock (std_logic)
--      Clock for LVDS inputs
-- @param[in] lvds_control (std_logic)
--      LVDS control signal
-- @param[in] lvds_n (unsigned[15])
--      LVDS input (together with lvds_p)
-- @param[in] lvds_p (unsigned[15])
--      LVDS input (together with lvds_n)
entity vnir_subsystem is
    port (
        clock           : in std_logic;
        reset_n         : in std_logic;
        vnir_config     : in vnir_config_t;
        config_done     : out std_logic;
        row_available   : out std_logic;
        row_1           : out vnir_row_t;
        row_2           : out vnir_row_t;
        row_3           : out vnir_row_t;
        sensor_clock    : out std_logic;
        sensor_reset    : out std_logic;
        spi_clock       : out std_logic;
        spi_miso        : out std_logic;
        spi_ss          : out std_logic;
        spi_mosi        : out std_logic;
        frame_request   : out std_logic;
        lvds_clock      : in std_logic;
        lvds_control     : in std_logic;
        lvds_n, pvds_p  : in unsigned (14 downto 0);
    );
end entity vnir_subsystem;
