-- electra_fpga_subsystem.vhd
----------------------------------------------------------------
-- Copyright 2020 University of Alberta

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
----------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

use work.avalonmm_types.all;
use work.sdram_types.all;
use work.vnir_types.all;
use work.swir_types.all;
use work.fpga_types.all;

entity electra_fpga_subsystem is
	port (

		reset_n                : in  std_logic                     := '0';                   --        reset.reset_n
		clock                  : in  std_logic                     := '0';                   --        clock.clk
	
		-- avalon MM interface
		avalon_slave_write_n   : in  std_logic                     := '0';                   -- avalon_slave.write_n
		avalon_slave_writedata : in  std_logic_vector(31 downto 0) := (others => '0');       --             .writedata
		avalon_slave_read_n    : in  std_logic                     := '0';                   --             .read_n
		avalon_slave_readdata  : out std_logic_vector(31 downto 0)                          --             .readdata

	);
end entity electra_fpga_subsystem;

architecture rtl of electra_fpga_subsystem is

	-- TODO:
		-- pass VNIR information to subsystem
		-- pass SDRAM information to subsystem
		-- pass SWIR information to subsystem
		-- add PLL IP to system for clocking to subsystems

	component vnir_subsystem is
	port (
		clock               : in std_logic;
		reset_n             : in std_logic;
	
		sensor_clock        : in std_logic;
		sensor_clock_locked : in std_logic;
		sensor_reset        : out std_logic;
	
		config              : in vnir_config_t;
		config_done         : out std_logic;
		
		do_imaging          : in std_logic;
	
		num_rows            : out integer;
		row                 : out vnir_row_t;
		row_available       : out vnir_row_type_t;
		
		spi_out             : out spi_from_master_t;
		spi_in              : in spi_to_master_t;
		
		frame_request       : out std_logic;
		exposure_start      : out std_logic;
		lvds                : in vnir_lvds_t
	);
	end component;

	component sdram_subsystem is
		port (
			--Control signals
			clock               : in std_logic;
			reset_n             : in std_logic;
	
			--VNIR row signals
			vnir_rows_available : in std_logic;
			vnir_num_rows       : in integer;
			vnir_rows           : in vnir_rows_t;
			
			--SWIR row signals
			swir_row_available  : in std_logic;
			swir_num_rows       : in integer;
			swir_row            : in swir_row_t;
			
			timestamp           : in timestamp_t;
			mpu_memory_change   : in sdram_address_block_t;
			config_in           : in sdram_config_to_sdram_t;
			config_out          : out sdram_partitions_t;
			config_done         : out std_logic;
			img_config_done     : out std_logic;
			
			sdram_busy          : out std_logic;
			sdram_error         : out stdram_error_t;
			
			sdram_avalon_out    : out avalonmm_rw_from_master_t;
			sdram_avalon_in     : in avalonmm_rw_to_master_t
		);
	end component sdram_subsystem;

	-- add signals here
	--

	-- add STATES here, if applicable
	--

begin

	vnir_subsystem_component: vnir_subsystem port map (
		clock               => clock, 
		reset_n             => reset_n, 
	
		sensor_clock        => sensor_clock,
		sensor_clock_locked => sensor_clock_locked,
		sensor_reset        => sensor_reset,
	
		config              => config,
		config_done         => config_done,
		
		do_imaging          => do_imaging, 
	
		num_rows            => num_rows, 
		row                 => row,
		row_available       => row_available,
		
		spi_out             => spi_out,
		spi_in              => spi_in,
		
		frame_request       => frame_request,
		exposure_start      => exposure_start,
		lvds                => lvds
	);
	
	sdram_subsystem_component: sdram_subsystem port map (
		clock               => clock,
		reset_n             => reset_n,
	
		vnir_rows_available => vnir_rows_available,
		vnir_num_rows       => vnir_num_rows,
		vnir_rows           => vnir_rows,

		swir_row_available  => siwr_row_available,
		swir_num_rows       => swir_num_rows,
		swir_row            => swir_row,
			
		timestamp           => timestamp,
		mpu_memory_change   => mpu_memory_change,
		config_in           => config_in,
		config_out          => config_out,
		config_done         => config_done,
		img_config_done     => img_config_done,
			
		sdram_busy          => sdram_busy,
		sdram_error         => sdram_error,
			
		sdram_avalon_out    => sdram_avalon_out,
		sdram_avalon_in     => sdram_avalon_in
	);
	
	-- BELOW: auto-generated grounding of outputs

	avalon_slave_readdata <= "00000000000000000000000000000000";

end architecture rtl; -- of electra_fpga_subsystem
