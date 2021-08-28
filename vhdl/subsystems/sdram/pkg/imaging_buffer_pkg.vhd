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

use work.swir_types;

package img_buffer_pkg is
    --Generating 1 buffer for each, allowing for storage of up to 1 row
    --Do not change the number of fifos, as the logic to handle them is written for these numbers, ie. 1 fifo per row type
    constant NUM_SWIR_ROW_FIFO : integer := 1;  
    constant NUM_VNIR_ROW_FIFO : integer := 3;  -- needs 3 fifos for the 3 sensors (red, blue and NIR)

    constant FIFO_WORD_LENGTH : integer := 128;  
    constant FIFO_WORD_BYTES : integer := FIFO_WORD_LENGTH/8;  -- for command creator

    --Number of words in swir and vnir fifo
    --Changing these requires changes to the VNIR and SWIR row fifo IPs. Specifically, change lpm_numwords
    constant VNIR_FIFO_DEPTH : integer := 160;  
    constant SWIR_FIFO_DEPTH : integer := 64;   

    --
    constant VNIR_ROW_BYTES  : integer := FIFO_WORD_BYTES * VNIR_FIFO_DEPTH;
    constant SWIR_ROW_BYTES  : integer := FIFO_WORD_BYTES * SWIR_FIFO_DEPTH;

    --vnir & swir row fragments are split into their respective FIFO word lengths
    subtype row_fragment_t is std_logic_vector (FIFO_WORD_LENGTH-1 downto 0);

    --The links between the vnir and swir fifos
    type vnir_link_a is array (0 to NUM_VNIR_ROW_FIFO-1) of row_fragment_t;
    type swir_link_a is array (0 to NUM_SWIR_ROW_FIFO-1) of row_fragment_t;

    type vnir_row_fragment_a is array (0 to VNIR_FIFO_DEPTH-1) of row_fragment_t;
    type swir_row_fragment_a is array (0 to SWIR_FIFO_DEPTH-1) of row_fragment_t;

    type row_type_tracker_a is array (0 to NUM_VNIR_ROW_FIFO-1) of std_logic;
    type row_buffer_a is array (0 to NUM_VNIR_ROW_FIFO-1) of vnir_row_fragment_a;
    type frag_count_a is array (0 to NUM_VNIR_ROW_FIFO-1) of natural range 0 to VNIR_FIFO_DEPTH;

    subtype swir_pixel_stdlogicvector_t is std_logic_vector(0 to swir_types.SWIR_PIXEL_BITS-1);

    -- functions for converting from swir pixel to std_logic_vector and back
    function swir_pixel_to_stdlogicvector(px_in : swir_types.swir_pixel_t) return swir_pixel_stdlogicvector_t;
    function stdlogicvector_to_swir_pixel(data_in : swir_pixel_stdlogicvector_t) return swir_types.swir_pixel_t;

end package img_buffer_pkg;

package body img_buffer_pkg is

    function swir_pixel_to_stdlogicvector(px_in : swir_types.swir_pixel_t) return swir_pixel_stdlogicvector_t is
        variable stdlogicvect_out : swir_pixel_stdlogicvector_t;
    begin
        for i in stdlogicvect_out'range loop
            stdlogicvect_out(i) := px_in(i);
        end loop;
        return stdlogicvect_out;
    end function;

    function stdlogicvector_to_swir_pixel(stdlogicvect_in : swir_pixel_stdlogicvector_t) return swir_types.swir_pixel_t is
        variable px_out : swir_types.swir_pixel_t;
    begin
        for i in px_out'range loop
            px_out(i) := stdlogicvect_in(i);
        end loop;
        return px_out;
    end function;

end package body img_buffer_pkg;