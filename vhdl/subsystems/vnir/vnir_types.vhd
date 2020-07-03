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


package vnir_types is

    constant vnir_pixel_bits : integer := 12;
    constant vnir_row_width  : integer := 2048;
    subtype vnir_pixel_t is unsigned(0 to vnir_pixel_bits-1);
    type vnir_row_t is array(0 to vnir_row_width-1) of vnir_pixel_t;

    type vnir_rows_t is record
        blue : vnir_row_t;
        red  : vnir_row_t;
        nir  : vnir_row_t;
    end record vnir_rows_t;

    constant vnir_spi_num_reg : integer := 14;

    constant vnir_lvds_data_width : integer := 4;
    type vnir_lvds_t is record
        clock   : std_logic;
        control : std_logic;
        data  : std_logic_vector (0 to vnir_lvds_data_width-1);
    end record vnir_lvds_t;

    type vnir_pixel_vector_t is array(integer range <>) of vnir_pixel_t;

    type vnir_window_t is record
        lo  : integer range 0 to vnir_row_width-1;
        hi  : integer range 0 to vnir_row_width-1;
    end record vnir_window_t;

    type vnir_config_t is record
        start_config     : std_logic;
        window_blue      : vnir_window_t;
        window_red       : vnir_window_t;
        window_nir       : vnir_window_t;
        imaging_duration : integer;
        fps              : integer;
    end record vnir_config_t;

end package vnir_types;
