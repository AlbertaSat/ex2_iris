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

package swir_types is
    type swir_config_t is record
        frame_clocks	: integer;
        exposure_clocks : integer;
		length			: integer;
    end record swir_config_t;

    constant swir_pixel_bits : integer := 16;
    constant swir_row_width : integer := 512;
    type swir_pixel_t is array(0 to swir_pixel_bits-1) of std_logic;
end package swir_types;
