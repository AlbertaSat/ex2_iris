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

use work.vnir_base.all;
use work.integer_types.all;

package row_collector_pkg is
    constant MAX_N_WINDOWS : integer := 10;

    type config_t is record
        windows : window_vector_t(MAX_N_WINDOWS-1 downto 0);
        image_length : integer;
    end record config_t;

    type fragment_idx_t is record
        fragment : integer;
        row      : integer;
        window   : integer;
        frame    : integer;

        fragments_per_row : integer;
        rows_per_window : integer_vector_t(MAX_N_WINDOWS-1 downto 0);
        windows_per_frame : integer;
    end record fragment_idx_t;

    type status_t is record
        fragment_available  : std_logic;
        fragment_x          : integer;
    end record status_t;

    pure function is_last_fragment (idx : fragment_idx_t) return boolean;
    pure function is_last_row (idx : fragment_idx_t) return boolean;
    pure function is_last_window (idx : fragment_idx_t) return boolean;
    pure function window_size (idx : fragment_idx_t) return integer;
    procedure clear (idx : inout fragment_idx_t);
    procedure increment (idx : inout fragment_idx_t);

    pure function sizes(windows : window_vector_t) return integer_vector_t;

end package row_collector_pkg;

package body row_collector_pkg is

    pure function is_last_fragment(idx : fragment_idx_t) return boolean is
    begin
        return idx.fragment = idx.fragments_per_row - 1;
    end function is_last_fragment;

    pure function is_last_row(idx : fragment_idx_t) return boolean is
    begin
        return idx.row = idx.rows_per_window(idx.window) - 1;
    end function is_last_row;

    pure function is_last_window(idx : fragment_idx_t) return boolean is
    begin
        return idx.window = idx.windows_per_frame - 1;
    end function is_last_window;

    pure function window_size(idx : fragment_idx_t) return integer is
    begin
        return idx.rows_per_window(idx.window);
    end function window_size;

    procedure clear (idx : inout fragment_idx_t) is
    begin
        idx.fragment := 0;
        idx.row := 0;
        idx.window := 0;
        idx.frame := 0;
    end procedure clear;

    procedure increment (idx : inout fragment_idx_t) is
        variable rolled_over : boolean;
    begin
        increment_rollover(idx.fragment, idx.fragments_per_row, true, rolled_over);
        increment_rollover(idx.row, idx.rows_per_window(idx.window), rolled_over, rolled_over);
        increment_rollover(idx.window, idx.windows_per_frame, rolled_over, rolled_over);
        increment(idx.frame, rolled_over);
    end procedure increment;

    pure function sizes(windows : window_vector_t) return integer_vector_t is
        variable sizes : integer_vector_t(windows'range);
    begin
        for i in windows'range loop
            sizes(i) := size(windows(i));
        end loop;
        return sizes;
    end function sizes;

end package body row_collector_pkg;
