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

    constant vnir_pixel_bits : integer := 10;
    constant vnir_row_width  : integer := 2048;
    constant vnir_lvds_n_channels : integer := 16;
    
    subtype vnir_pixel_t is unsigned(vnir_pixel_bits-1 downto 0);
    type vnir_pixel_vector_t is array(integer range <>) of vnir_pixel_t;
    subtype vnir_row_t is vnir_pixel_vector_t(vnir_row_width-1 downto 0);

    type vnir_row_type_t is (ROW_NONE, ROW_NIR, ROW_BLUE, ROW_RED);

    type vnir_rows_t is record
        blue : vnir_row_t;
        red  : vnir_row_t;
        nir  : vnir_row_t;
    end record vnir_rows_t;

    type vnir_window_t is record
        lo  : integer range 0 to vnir_row_width-1;
        hi  : integer range 0 to vnir_row_width-1;
    end record vnir_window_t;

    type vnir_flip_t is (FLIP_NONE, FLIP_X, FLIP_Y, FLIP_XY);

    type vnir_config_t is record
        window_blue      : vnir_window_t;
        window_red       : vnir_window_t;
        window_nir       : vnir_window_t;
        imaging_duration : integer;
        fps              : integer;
        exposure_time    : integer;
        flip             : vnir_flip_t;
    end record vnir_config_t;

    type vnir_lvds_t is record
        clock     : std_logic;
        control   : std_logic;
        data      : std_logic_vector (vnir_lvds_n_channels-1 downto 0);
    end record vnir_lvds_t;

    type vnir_control_t is record
        dval : std_logic;
        lval : std_logic;
        fval : std_logic;
        slot : std_logic;
        row : std_logic;
        fot : std_logic;
        inte1 : std_logic;
        inte2 : std_logic;
    end record vnir_control_t;
    
    type vnir_parallel_lvds_t is record
        control : vnir_control_t;
        data : vnir_pixel_vector_t (vnir_lvds_n_channels-1 downto 0);
    end record vnir_parallel_lvds_t;

    pure function size(window : vnir_window_t) return integer;
    pure function total_rows (config : vnir_config_t) return integer;
    pure function to_vnir_control (ctrl_bits : std_logic_vector) return vnir_control_t;

end package vnir_types;


package body vnir_types is
    pure function size(window : vnir_window_t) return integer is
    begin
        return window.hi - window.lo + 1;
    end function size;

    pure function total_rows (config : vnir_config_t) return integer is
    begin
        return size(config.window_red) + size(config.window_blue) + size(config.window_nir);
    end function total_rows;

    pure function to_vnir_control (ctrl_bits : std_logic_vector) return vnir_control_t is
    begin
        return (
            dval => ctrl_bits(ctrl_bits'left-0),
            lval => ctrl_bits(ctrl_bits'left-1),
            fval => ctrl_bits(ctrl_bits'left-2),
            slot => ctrl_bits(ctrl_bits'left-3),
            row => ctrl_bits(ctrl_bits'left-4),
            fot => ctrl_bits(ctrl_bits'left-5),
            inte1 => ctrl_bits(ctrl_bits'left-6),
            inte2 => ctrl_bits(ctrl_bits'left-7)
        );
    end function to_vnir_control;

end package body vnir_types;
