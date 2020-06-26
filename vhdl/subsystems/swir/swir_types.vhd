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
        start_config     : std_logic;
        imaging_duration : integer;
        -- TODO: add other configuration parameters here, e.g. framerate.
    end record swir_config_t;

    type swir_control_t is record
        some_element : std_logic;  -- TODO: add control values
    end record swir_control_t;


    constant swir_pixel_bits : integer := 16;  -- TODO: define this
    constant swir_row_width : integer := 512; -- TODO: define this
    subtype swir_pixel_t is unsigned(0 to swir_pixel_bits-1);
    type swir_row_t is array(0 to swir_row_width-1) of swir_pixel_t;
end package swir_types;
