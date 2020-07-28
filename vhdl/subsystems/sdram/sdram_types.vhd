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
    type sdram_address_block_t is array (0 to 1) of unsigned(31 downto 0);
    
    type sdram_error_t is (no_error, full, mpu_check_failed);

    type vnir_row_available_t is (no_row, blue_row, red_row, nir_row);

    type sdram_next_row_fed_t is (no_row, blue_row, red_row, nir_row, swir_row);

    type sdram_config_to_sdram_t is record
        memory_base     : unsigned(31 downto 0);
        memory_bounds   : unsigned(31 downto 0);
    end record sdram_config_to_sdram_t;

    type partition_t is record
        base               : unsigned(31 downto 0);
        bounds             : unsigned(31 downto 0);
        fill_bounds        : unsigned(31 downto 0);
        fill_base          : unsigned(31 downto 0);
    end record partition_t;

    constant UNDEFINED_PARTITION : partition_t := (
        base => 0,
        bounds => 0,
        fill_base => 0,
        fill_bounds => 0);

    type sdram_partitions_t is record
        vnir        : partition_t;
        swir        : partition_t;
        vnir_temp   : partition_t;
        swir_temp   : partition_t;
    end record sdram_partitions_t;
end package sdram_types;
