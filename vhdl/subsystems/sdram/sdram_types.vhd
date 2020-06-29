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
        memory_base : integer;
        memory_bounds : integer;
    end record sdram_config_t;

    type sdram_filled_addresses_t is record
        todo : std_logic;
    end record sdram_filled_addresses_t;

    type sdram_error_t is (SDRAM_NO_ERROR, SDRAM_FULL, SDRAM_MPU_CHECK_FAILED);
end package sdram_types;
