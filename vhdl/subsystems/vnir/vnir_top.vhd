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

use work.vnir_common.all;

package vnir_top is

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
    
end package vnir_top;
