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

use work.vnir_base;

package vnir is

    -- TODO: this shouldn't be here
    type flip_t is (FLIP_NONE, FLIP_X, FLIP_Y, FLIP_XY);

    constant ROW_WIDTH : integer := 2048;
    constant FRAGMENT_WIDTH : integer := 16;
    constant PIXEL_BITS : integer := 10;
    constant ROW_PIXEL_BITS : integer := 10;  -- Increase this to prevent overflow if using method = SUM
    constant N_WINDOWS : integer := 3;
    constant MAX_WINDOW_SIZE : integer := 16;
    constant METHOD : string := "AVERAGE";

    constant MAX_FPS : integer := 2000;

    subtype pixel_t is vnir_base.pixel_t(PIXEL_BITS-1 downto 0);
    subtype row_t is vnir_base.pixel_vector_t(ROW_WIDTH-1 downto 0)(ROW_PIXEL_BITS-1 downto 0);
    
    subtype window_t is vnir_base.window_t;
    subtype calibration_t is vnir_base.calibration_t;

    type config_t is record
        window_blue      : window_t;
        window_red       : window_t;
        window_nir       : window_t;
        flip             : flip_t;
        calibration      : calibration_t;
    end record config_t;

    type image_config_t is record
        duration        : integer;
        fps             : integer;
        exposure_time   : integer;
    end record image_config_t;

    type row_type_t is (ROW_NONE, ROW_NIR, ROW_BLUE, ROW_RED);
    
    type lvds_t is record
        clock   : std_logic;
        control : std_logic;
        data    : std_logic_vector(FRAGMENT_WIDTH-1 downto 0);
    end record lvds_t;

end package vnir;
