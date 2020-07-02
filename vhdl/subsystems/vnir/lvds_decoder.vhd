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

use work.vnir_types.all;

entity lvds_decoder_12 is
port (
    clock          : in std_logic;
    reset_n        : in std_logic;
    start_align    : in std_logic;
    align_done     : out std_logic;
    lvds_in        : in vnir_lvds_t;
    parallel_out   : out vnir_pixel_vector_t(0 to 5-1);
    data_available : out std_logic
);
end entity lvds_decoder_12;

