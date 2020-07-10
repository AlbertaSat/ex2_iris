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
use work.fpga_types.all;

package sdram_types is
    type sdram_address_block_t is array (0 to 1) of integer;

    type sdram_error_t is (SDRAM_NO_ERROR, SDRAM_FULL, SDRAM_MPU_CHECK_FAILED);

    type sdram_next_row_fed is (NO_ROW, BLUE_ROW, RED_ROW, NIR_ROW, SWIR_ROW);

    type sdram_config_to_sdram_t is record
        memory_base     : integer;
        memory_bounds   : integer;
    end record sdram_config_to_sdram_t;

    type sdram_config_from_sdram_t is record
        swir_base           : integer;
        swir_bounds         : integer;
        swir_temp_base      : integer;
        swir_temp_bounds    : integer;
        vnir_base           : integer;
        vnir_bounds         : integer;
        vnir_temp_base      : integer;
        vnir_temp_bounds    : integer;
    end record sdram_config_from_sdram_t;
    
    type sdram_header_t is record
        timestamp        : timestamp_t;
        user_defined     : std_logic_vector (7 downto 0);
        x_size           : integer range 0 to 2**16 - 1;
        y_size           : integer range 0 to 2**16 - 1;
        z_size           : integer range 0 to 2**16 - 1;
        sample_type      : std_logic;
        reserved_1       : std_logic_vector (1 downto 0);
        dyna_range       : integer;
        sample_encode    : std_logic;
        interleave_depth : std_logic_vector (15 downto 0);
        reserved_2       : std_logic_vector (1 downto 0);
        output_word      : integer;
        entropy_coder    : std_logic;
        reserved_3       : std_logic_vector (9 downto 0);
    end record sdram_header_t;
end package sdram_types;
