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

package lvds_decoder_pkg is

    constant FRAGMENT_BITS : integer := FRAGMENT_WIDTH * PIXEL_BITS;

    type fifo_data_t is record
        fragment    : fragment_t;
        control     : control_t;
        is_aligned  : std_logic;
    end record fifo_data_t;

    constant FIFO_DATA_BITS : integer := FRAGMENT_WIDTH*PIXEL_BITS  -- fragment
                                        + 8  -- control
                                        + 1;  -- is_aligned

    pure function flatten(fragment : fragment_t) return std_logic_vector;
    pure function unpack_to_fragment(fragment_flat : std_logic_vector) return fragment_t;

    pure function flatten(data : fifo_data_t) return std_logic_vector;
    pure function unpack_to_fifo_data(data : std_logic_vector) return fifo_data_t;
    
    pure function rotate_right(bits : std_logic_vector; i : integer) return std_logic_vector;
    pure function calc_align_offset(control : std_logic_vector;
                                    control_target : std_logic_vector)
                                    return integer;

    pure function bitreverse(bits : std_logic_vector) return std_logic_vector;
    pure function bitreverse(bits : unsigned) return unsigned;
    pure function bitreverse(fragment : fragment_t) return fragment_t;

end package lvds_decoder_pkg;


package body lvds_decoder_pkg is

    pure function flatten(fragment : fragment_t) return std_logic_vector is
        variable fragment_flat : std_logic_vector(FRAGMENT_BITS-1 downto 0);
    begin
        for i_pixel in fragment'range loop
            for i_bit in fragment(0)'range loop
                fragment_flat(i_bit + i_pixel * PIXEL_BITS) := fragment(i_pixel)(i_bit);
            end loop;
        end loop;
        return fragment_flat;
    end function flatten;

    pure function unpack_to_fragment(fragment_flat : std_logic_vector) return fragment_t is
        variable fragment : fragment_t;
    begin
        for i_pixel in fragment'range loop
            for i_bit in fragment(0)'range loop
                fragment(i_pixel)(i_bit) := fragment_flat(i_bit + i_pixel * PIXEL_BITS);
            end loop;
        end loop;
        return fragment;
    end function unpack_to_fragment;

    pure function flatten(data : fifo_data_t) return std_logic_vector is
        variable data_flat : std_logic_vector(FIFO_DATA_BITS-1 downto 0);
    begin
        data_flat(FRAGMENT_BITS + 8) := data.is_aligned;
        data_flat(FRAGMENT_BITS + 7 downto FRAGMENT_BITS) := to_logic8(data.control);
        data_flat(FRAGMENT_BITS - 1 downto 0) := flatten(data.fragment);
        return data_flat;
    end function flatten;

    pure function unpack_to_fifo_data(data : std_logic_vector) return fifo_data_t is
        variable fifo_data : fifo_data_t;
    begin
        fifo_data.is_aligned := data(FRAGMENT_BITS + 8);
        fifo_data.control    := to_control(data(FRAGMENT_BITS + 7 downto FRAGMENT_BITS));
        fifo_data.fragment   := unpack_to_fragment(data(FRAGMENT_BITS - 1 downto 0));
        return fifo_data;
    end function unpack_to_fifo_data;

    pure function rotate_right(bits : std_logic_vector; i : integer) return std_logic_vector is
    begin
        return std_logic_vector(rotate_right(unsigned(bits), i));
    end function rotate_right;

    pure function calc_align_offset(control : std_logic_vector; control_target : std_logic_vector)
                                    return integer is
    begin
        for i in 0 to control'length-1 loop
            if rotate_right(control, i) = control_target then
                return i;
            end if;
        end loop;

        report "Can't compute align offset" severity failure;
        return 0;  -- TODO: trigger some kind of error if we get here
    end function calc_align_offset;

    pure function bitreverse(bits : std_logic_vector) return std_logic_vector is
        variable bits_reversed : std_logic_vector(bits'range);
    begin
        for i in bits'range loop
            bits_reversed(bits_reversed'high - i) := bits(i);
        end loop;
        return bits_reversed;
    end function bitreverse;

    pure function bitreverse(bits : unsigned) return unsigned is
    begin
        return unsigned(bitreverse(std_logic_vector(bits)));
    end function bitreverse;

    pure function bitreverse(fragment : fragment_t) return fragment_t is
        variable fragment_reversed : fragment_t;
    begin
        for i_pixel in fragment'range loop
            fragment_reversed(i_pixel) := bitreverse(fragment(i_pixel));
        end loop;
        return fragment_reversed;
    end function bitreverse;

end package body lvds_decoder_pkg;
