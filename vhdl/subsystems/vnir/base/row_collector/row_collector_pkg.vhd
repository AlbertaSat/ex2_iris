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
        length : integer;
    end record config_t;

    type edge_type_t is (INTERIOR, LEADING, LAGGING);

    type fragment_idx_t is record
        x           : integer;
        i_fragment  : integer;
        i_window    : integer;
        is_leading  : boolean;
        is_lagging  : boolean;
    end record fragment_idx_t;

    type status_t is record
        fragment_available  : std_logic;
        fragment_x          : integer;
    end record status_t;

    pure function sizes(windows : window_vector_t) return integer_vector_t;

end package row_collector_pkg;

package body row_collector_pkg is

    pure function sizes(windows : window_vector_t) return integer_vector_t is
        variable sizes : integer_vector_t(windows'range);
    begin
        for i in windows'range loop
            sizes(i) := size(windows(i));
        end loop;
        return sizes;
    end function sizes;

end package body row_collector_pkg;
