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

package sdram_types is
    type sdram_config_t is record
        memory_base     : integer;
        memory_bounds   : integer;
    end record sdram_config_t;

    subtype sdram_address_block_t is array(0 to 1) of integer;

    type sdram_error_t is (SDRAM_NO_ERROR, SDRAM_FULL, SDRAM_MPU_CHECK_FAILED);

    type sdram_next_row_fed is (NO_ROW, BLUE_ROW, RED_ROW, NIR_ROW, SWIR_ROW);

    type sdram_config_to_sdram_t is record
        memory_base     : integer;
        memory_bounds   : integer;
    end record sdram_config_in_t;

    type sdram_config_from_sdram_t is record
        swir_base           : integer;
        swir_bounds         : integer;
        swir_temp_base      : integer;
        swir_temp_bounds    : integer;
        vnir_base           : integer;
        vnir_bounds         : integer;
        vnir_temp_base      : integer;
        vnir_temp_bounds    : integer;
    end record sdram_config_out_t;

    type sdram_config is record
        to_sdram : sdram_config_to_sdram_t;
        from_sdram : sdram_config_from_sdram_t;
    end record sdram_config;

    subtype sdram_header is std_logic_vector (0 to 160)

end package sdram_types;
