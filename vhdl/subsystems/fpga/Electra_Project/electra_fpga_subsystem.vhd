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
		-- pass VNIR config information to subsystem [DONE]
		-- pass SDRAM config information to subsystem [DONE]
		-- pass SWIR config information to subsystem
		-- pass image config information to subsystems [DONE, not for SWIR]
		-- add clock to system
		-- write timestamp code
		-- put this into ClickUp

	component vnir_subsystem is
	port (
		clock               : in std_logic;
		reset_n             : in std_logic;
	
		sensor_clock        : in std_logic;
		sensor_clock_locked : in std_logic;
		sensor_power        : out std_logic;
		sensor_clock_enable : out std_logic;
		sensor_reset_n      : out std_logic;
	
		config              : in vnir_config_t;
		start_config        : in std_logic;
		config_done         : out std_logic;
		
		image_config        : in vnir_image_config_t;
		start_image_config  : in std_logic;
		image_config_done   : out std_logic;
		num_rows            : out integer;
		
		do_imaging          : in std_logic;
		imaging_done        : out std_logic;
	
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
			start_config        : in std_logic
			config_out          : out sdram_partitions_t;
			config_done         : out std_logic;
			img_config_done     : out std_logic;
			
			sdram_busy          : out std_logic;
			sdram_error         : out stdram_error_t;
			
			sdram_avalon_out    : out avalonmm_rw_from_master_t;
			sdram_avalon_in     : in avalonmm_rw_to_master_t
		);
	end component sdram_subsystem;

-- flag for if some other 8-bit vector enters our Avalon CASE structure
signal unexpected_identifier: std_logic := '0';

-- VNIR config signals
signal vnir_config: vnir_config_t;
signal vnir_start_config: std_logic;
signal vnir_config_done: std_logic;


-- SDRAM config signals
signal sdram_config_out: sdram_config_to_sdram_t
signal sdram_start_config: std_logic;

-- image config signals
signal vnir_image_config: vnir_image_config_t;
signal vnir_start_image_config: std_logic;
signal vnir_image_config_done: std_logic;

begin

	vnir_subsystem_component: vnir_subsystem port map (
		clock               => clock
		reset_n             => reset_n
	
		sensor_clock        => sensor_clock
		sensor_clock_locked => sensor_clock_locked
		sensor_power        => sensor_power
		sensor_clock_enable => sensor_clock_enable
		sensor_reset_n      => sensor_reset_n
	
		config              => vnir_config 
		start_config        => vnir_start_config
		config_done         => vnir_config_done
		
		image_config        => vnir_image_config 
		start_image_config  => vnir_start_image_config
		image_config_done   => vnir_image_config_done
		num_rows            => num_rows
		
		do_imaging          => vnir_do_imaging 
		imaging_done        => vnir_imaging_done
	
		row                 => row 
		row_available       => row_available
		
		spi_out             => spi_out
		spi_in              => spi_in 
		
		frame_request       => frame_request
		exposure_start      => exposure_start
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
		config_in           => sdram_config_out,   -- sdram_config_out for "out" of FPGA subsystem
		start_config        => sdram_start_config,
		config_out          => sdram_config_in,    -- sdram_config_in for "in" to FPGA subsystem
		config_done         => sdram_config_done,
		img_config_done     => sdram_img_config_done,
			
		sdram_busy          => sdram_busy,
		sdram_error         => sdram_error,
			
		sdram_avalon_out    => sdram_avalon_in,    -- sdram_avalon_in for "in" to FPGA subsystem
		sdram_avalon_in     => sdram_avalon_out    -- sdram_avalon_out for "out" of FPGA subsystem
	);
	
	-- process for assigning data to subsystems based on identifier bits

	-- this program knows which bits to expect over the Avalon MM interface based on
	-- 8 identifier bits which comprise bits [7..0] of every transfer.

	avalon_write_process: process (write_n, clock)
	begin
		if (reset_n = '0') then
			-- something, maybe? Or not.
		else
		
			case avalon_write_data(7 downto 0) is 
				
				-- VNIR subsystem configuration
				
				when "00000001" =>
					vnir_config.window_blue.lo <= to_integer(unsigned(avalon_write_data(18 downto 8)));
					vnir_config.window_blue.hi <= to_integer(unsigned(avalon_write_data(29 downto 9)));
				
				when "00000010" => 
					vnir_config.window_red.lo <= to_integer(unsigned(avalon_write_data(18 downto 8)));
					vnir_config.window_red.hi <= to_integer(unsigned(avalon_write_data(29 downto 9)));

				when "00000011" => 
					vnir_config.window_nir.lo <= to_integer(unsigned(avalon_write_data(18 downto 8)));
					vnir_config.window_nir.hi <= to_integer(unsigned(avalon_write_data(29 downto 9)));
				
				when "00000100" =>
					vnir_config.calibration.vramp1 <= to_integer(unsigned(avalon_write_data(14 downto 8)));
					vnir_config.calibration.vramp2 <= to_integer(unsigned(avalon_write_data(21 downto 15)));
					vnir_config.calibration.adc_gain <= to_integer(unsigned(avalon_write_data(29 downto 22)));
				
					if (avalon_write_data(31 downto 30) = "00") then
						vnir_config.flip <= FLIP_NONE;
					elsif (avalon_write_data(31 downto 30) = "01") then
						vnir_config.flip <= FLIP_X;
					elsif (avalon_write_data(31 downto 30) = "10") then
						vnir_config.flip <= FLIP_Y;
					else
						vnir_config.flip <= FLIP_XY;
					end if;
				
				when "00000101" =>
					vnir_config.calibration.offset <= to_integer(unsigned(avalon_write_data(21 downto 8)));
			
					vnir_start_config <= avalon_write_data(22); -- will be a '1' to start config

				
				-- SDRAM subsystem configuration 
				-- Note that Avalon MM 32-bit wide interface not large enough with identifier bits, so
				-- we need to split up the memory base and bounds into multiple transfers
				
				when "00000110" =>
					sdram_config_out.memory_base(23 downto 0) <= unsigned(avalon_write_data(31 downto 8));
				
				when "00000111" =>
					sdram_config_out.memory_base(27 downto 24) <= unsigned(avalon_write_data(11 downto 8));
					sdram_config_out.memory_bounds(19 downto 0) <= unsigned(avalon_write_data(31 downto 12));
				
				when "00001000" =>
					sdram_config_out.memory_base(27 downto 20) <= unsigned(avalon_write_data(15 downto 8));
					
					sdram_start_config <= avalon_write_data(16); -- will be a '1' to start config

				-- SWIR subsystem configuration 
				-- TO DO: add all SWIR

				-- image config
				-- TO DO: add SWIR code for image config data
				
				when "00001001" =>
					vnir_image_config.duration <= to_integer(unsigned(avalon_write_data(23 downto 8)));
					vnir_image_config.exposure_time <= to_integer(unsigned(avalon_write_data(31 downto 24)));
					
				when "00001010" =>	
					vnir_image_config.fps <= to_integer(unsigned(avalon_write_data(17 downto 8)));

					vnir_start_image_config <= avalon_write_data(18); -- will be a '1' to start config

				-- general signals

				when "00010000" =>
					-- init_timestamp (write this code)

				when "00010001" =>
					vnir_do_imaging <= avalon_write_data(8);
					

				when others =>
					unexpected_identifier <= '1';
			
			end case;

		end if;
	
	end process;

	
	-- BELOW: auto-generated grounding of outputs

	avalon_slave_readdata <= "00000000000000000000000000000000";

end architecture rtl; -- of electra_fpga_subsystem
