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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.avalonmm;
use work.sdram;
use work.vnir;
use work.swir_types.all;
use work.fpga_types.all;


entity sdram_subsystem is
    port (
        --Control signals
        clock               : in std_logic;
        reset_n             : in std_logic;

        --VNIR row signals
        vnir_rows_available : in vnir.row_type_t;
        vnir_num_rows       : in integer;
        vnir_rows           : in vnir.row_t;
        
        --SWIR row signals
        swir_row_available  : in std_logic;
        swir_num_rows       : in integer;
        swir_row            : in swir_row_t;
        
        timestamp           : in timestamp_t;
        mpu_memory_change   : in sdram.address_block_t;
        config_in           : in sdram.config_to_sdram_t;
        start_config        : in std_logic;
        config_out          : out sdram.memory_state_t;
        config_done         : out std_logic;
        img_config_done     : out std_logic;
        
        sdram_busy          : out std_logic;
        sdram_error         : out sdram.error_t;
        
        sdram_avalon_out    : out avalonmm.from_master_t;
        sdram_avalon_in     : in avalonmm.to_master_t
    );
end entity sdram_subsystem;

architecture rtl of sdram_subsystem is
    component memory_map is
        port(
            --Control signals
            clock               : in std_logic;
            reset_n             : in std_logic;

            --SDRAM config signals to and from the FPGA
            config              : in sdram.config_to_sdram_t;
            memory_state        : out sdram.memory_state_t;

            start_config        : in std_logic;
            config_done         : out std_logic;
            img_config_done     : out std_logic;

            --Image Config signals
            number_swir_rows    : in integer;
            number_vnir_rows    : in integer;

            --Ouput image row address config
            next_row_type       : in sdram.row_type_t;
            next_row_req        : in std_logic;
            output_address      : out sdram.address_t;

            --Read data to be read from sdram due to mpu interaction
            sdram_error         : out sdram.error_t
        );
    end component memory_map;

    component header_creator is
        port (
            --Control Signals
            clock           : in std_logic;
            reset_n         : in std_logic;

            --Timestamp for image dating
            timestamp       : in timestamp_t;

            --Header rows
            swir_img_header : out sdram.header_t;
            vnir_img_header : out sdram.header_t;

            -- Number of rows being created by the imagers
            vnir_rows       : in integer;
            swir_rows       : in integer;

            --Flag indicating the imager is working
            sending_img     : in std_logic
        );
    end component header_creator;

    component command_creator is
        port (
            --Control Signals
            clock               : in std_logic;
            reset               : in std_logic;

            --Header data
            vnir_img_header     : in sdram.header_t;
            swir_img_header     : in sdram.header_t;

            --Rows
            row_data            : in vnir.row_t;

            --Addy
            address             : in sdram.address_t;

            -- Flags for MPU interaction
            sdram_busy          : in std_logic;
            mpu_memory_change   : in sdram.address_block_t;

            --Avalon bridge for reading and writing to stuff
            sdram_avalon_out    : out avalonmm.from_master_t;
            sdram_avalon_in     : in avalonmm.to_master_t
        );
    end component command_creator;

    component imaging_buffer is
        port (
            --Control Signals
            clock           : in std_logic;
            reset_n         : in std_logic;

            --Rows of Data
            vnir_rows       : in vnir.row_t;
            swir_row        : in swir_row_t;

            --Rows out
            vnir_row_out    : out vnir.row_t;
            swir_row_out    : out swir_row_t;
            row_request     : in std_logic;

            --Flag signals
            swir_row_ready  : in std_logic;
            vnir_row_ready  : in vnir.row_type_t
        );
    end component imaging_buffer;
begin
end architecture;