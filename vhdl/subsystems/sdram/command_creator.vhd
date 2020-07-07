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

use work.spi_types.all;
use work.avalonmm_types.all;
use work.vnir_types.all;
use work.swir_types.all;
use work.sdram_types.all;
use work.fpga_types.all;

entity command_creator is
    port(
        --Control Signals
        clock               : in std_logic;
        reset               : in std_logic;

        --Header data
        vnir_img_header     : in sdram_header;
        swir_img_header     : in sdram_header;

        --Rows
        row_data            : in vnir_row_t;

        -- Flags for MPU interaction
        sdram_busy          : in std_logic;
        mup_memory_change   : in sdram_address_block_t;

        --Avalon bridge for reading and writing to stuff
        read_in             : in avalonmm_read_to_master_t;
        read_out            : out avalonmm_read_from_master_t;
        write_in            : in avalonmm_write_to_master_t;
        write_out           : out avalonmm_write_from_master_t;
    );
end entity command_creator;


