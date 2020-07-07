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

package lvds_decoder_pkg is
    constant n_fifo_channels : integer := vnir_lvds_data_width + 2; -- Add aligned and control
    subtype fifo_elem_t is std_logic_vector(vnir_pixel_bits-1 downto 0);
    subtype fifo_data_t is std_logic_vector(n_fifo_channels*vnir_pixel_bits-1 downto 0);

    pure function get(fifo_data : fifo_data_t; i : integer) return fifo_elem_t;
end package lvds_decoder_pkg;

package body lvds_decoder_pkg is
    pure function get(fifo_data : fifo_data_t; i : integer) return fifo_elem_t is
    begin
        return fifo_data(vnir_pixel_bits*(i+1)-1 downto vnir_pixel_bits*i);
    end function get;

end package body lvds_decoder_pkg;
