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


entity row_collator is
generic (
    sum_pixel_bits : integer := 19  -- ceil(log2(125 * (2 ^ 12 - 1) + 1))
);
port (
    clock            : in std_logic;
    reset_n          : in std_logic;
    config           : in vnir_config_t;
    read_config      : in std_logic;
    pixels           : in vnir_pixel_vector_t(0 to vnir_lvds_data_width-1);
    pixels_available : in std_logic;
    rows             : out vnir_rows_t;
    rows_available   : out std_logic
);
end entity row_collator;


architecture rtl of row_collator is
    subtype sum_pixel_t is unsigned(0 to sum_pixel_bits-1);
    type sum_row_t is array(0 to vnir_row_width-1) of sum_pixel_t;  

    pure function "/" (lhs : sum_row_t; rhs: integer) return sum_row_t is
        variable result : sum_row_t;
    begin
        for i in lhs'range loop
            result(i) := lhs(i) / rhs;
        end loop;
        return result;
    end function "/";

    procedure fill (row : inout sum_row_t; x : in std_logic) is
    begin
        row := (others => (others => x));
    end procedure fill;

    procedure add (
        sum_row : inout sum_row_t;
        pixels : in vnir_pixel_vector_t;
        offset : in integer;
        stride : in integer
    ) is
    begin
        for i in pixels'range loop
            sum_row(offset + stride * i) := sum_row(offset + stride * i) + pixels(i);
        end loop;
    end procedure add;

    pure function to_vnir_row (sum_row : sum_row_t) return vnir_row_t is
        variable row : vnir_row_t;
        variable sum_row_i : sum_pixel_t;
    begin
        for i in sum_row'range loop
            sum_row_i := sum_row(i);
            row(i) := sum_row_i(sum_pixel_bits-vnir_pixel_bits to sum_pixel_bits-1);
        end loop;
        return row;
    end function to_vnir_row;

    type counters_t is record
        chunk : integer;
        row   : integer; 
    end record counters_t;

    procedure restart (counters : inout counters_t) is
    begin
        counters := (others => 0);
    end procedure restart;

    procedure increment(
        counters : inout counters_t;
        max_chunks : in integer;
        max_rows : in integer
    ) is
    begin
        counters.chunk := counters.chunk + 1;
        if (counters.chunk = max_chunks) then
            counters.chunk := 0;
            counters.row := counters.row + 1;
        end if;
        if (counters.row = max_rows) then
            counters.row := 0;
        end if;
    end procedure increment;

begin

    main_process : process
        type state_t is (RESET, IDLE, DECODING_RED, DECODING_BLUE, DECODING_NIR);
        variable state : state_t;

        variable counters : counters_t;
        variable sum_row : sum_row_t;

        type window_sizes_t is record
            red : integer;
            blue : integer;
            nir : integer;
        end record window_sizes_t;
        variable window_sizes : window_sizes_t;

        constant chunks_per_row : integer := vnir_row_width / vnir_lvds_data_width;
    begin
        wait until rising_edge(clock);

        rows_available <= '0';

        if reset_n = '0' then
            state := RESET;
        end if;

        case state is
        when RESET =>
            state := IDLE;
        when IDLE =>
            if read_config = '1' then
                window_sizes.red := config.window_red.hi - config.window_red.lo + 1;
                window_sizes.blue := config.window_blue.hi - config.window_blue.lo + 1;
                window_sizes.nir := config.window_nir.hi - config.window_nir.lo + 1;
            end if;
            if pixels_available = '1' then
                state := DECODING_RED;
                fill(sum_row, '0');
                restart(counters);
                add(sum_row, pixels, counters.chunk, chunks_per_row);
                increment(counters, chunks_per_row, window_sizes.red);
            end if;
        when DECODING_RED =>
            if pixels_available = '1' then
                add(sum_row, pixels, counters.chunk, chunks_per_row);
                increment(counters, chunks_per_row, window_sizes.red);
                if (counters.chunk = 0 and counters.row = 0) then
                    rows.red <= to_vnir_row(sum_row / window_sizes.red);
                    fill(sum_row, '0');
                    restart(counters);
                    state := DECODING_BLUE;
                end if;
            end if;
        when DECODING_BLUE =>
            if pixels_available = '1' then
                add(sum_row, pixels, counters.chunk, chunks_per_row);
                increment(counters, chunks_per_row, window_sizes.red);
                if (counters.chunk = 0 and counters.row = 0) then
                    rows.blue <= to_vnir_row(sum_row / window_sizes.blue);
                    fill(sum_row, '0');
                    restart(counters);
                    state := DECODING_NIR;
                end if;
            end if;
        when DECODING_NIR =>
            if pixels_available = '1' then
                add(sum_row, pixels, counters.chunk, chunks_per_row);
                increment(counters, chunks_per_row, window_sizes.nir);
                if (counters.chunk = 0 and counters.row = 0) then
                    rows.nir <= to_vnir_row(sum_row / window_sizes.nir);
                    fill(sum_row, '0');
                    restart(counters);
                    state := IDLE;
                    rows_available <= '1';
                end if;
            end if;
        end case;
    end process;
end architecture rtl;
