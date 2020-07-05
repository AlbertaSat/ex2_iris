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
    constant pixels_per_row : integer := vnir_row_width / vnir_lvds_data_width;

    subtype sum_pixel_t is unsigned(0 to sum_pixel_bits-1);
    type sum_row_t is array(0 to vnir_row_width-1) of sum_pixel_t;  

    type counters_t is record
        pixel : integer;
        row 	: integer; 
    end record counters_t;

    procedure reset (
        variable counters : inout counters_t;
        variable sum_row : inout sum_row_t
    ) is
    begin
        counters.pixel := 0;
        counters.row := 0;
        sum_row := (others => (others => '0'));
    end procedure reset;
   
    procedure increment_sum (
        signal pixels : in vnir_pixel_vector_t(0 to vnir_lvds_data_width-1);
        variable sum_row : inout sum_row_t;
        variable counters : in counters_t
    ) is
    begin
        for i in 0 to vnir_lvds_data_width-1 loop
            sum_row(counters.pixel + pixels_per_row * i) := sum_row(counters.pixel + pixels_per_row * i) + pixels(i);
        end loop;
    end procedure increment_sum;

    procedure increment_counters (
        variable counters : inout counters_t;
        variable rows_per_window : in integer
    ) is
    begin
        counters.pixel := counters.pixel + 1;
        if (counters.pixel = pixels_per_row) then
            counters.pixel := 0;
            counters.row := counters.row + 1;
        end if;
        if (counters.row = rows_per_window) then
            counters.row := 0;
        end if;
    end procedure increment_counters;

    procedure sum_to_average (
        variable sum_row : in sum_row_t;
        variable rows_per_window : in integer;
        signal row : out vnir_row_t
    ) is
        variable t : sum_pixel_t;
    begin
        for i in 0 to vnir_row_width-1 loop
            t := sum_row(i) / rows_per_window;
            row(i) <= t(sum_pixel_bits-vnir_pixel_bits to sum_pixel_bits-1);
        end loop;
    end procedure sum_to_average;

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
                reset(counters, sum_row);
                increment_sum(pixels, sum_row, counters);
                increment_counters(counters, window_sizes.red);
            end if;
        when DECODING_RED =>
            if pixels_available = '1' then
                increment_sum(pixels, sum_row, counters);
                increment_counters(counters, window_sizes.red);
                if (counters.pixel = 0 and counters.row = 0) then
                    sum_to_average(sum_row, window_sizes.red, rows.red);
                    reset(counters, sum_row);
                    state := DECODING_BLUE;
                end if;
            end if;
        when DECODING_BLUE =>
            if pixels_available = '1' then
                increment_sum(pixels, sum_row, counters);
                increment_counters(counters, window_sizes.blue);
                if (counters.pixel = 0 and counters.row = 0) then
                    sum_to_average(sum_row, window_sizes.blue, rows.blue);
                    reset(counters, sum_row);
                    state := DECODING_NIR;
                end if;
            end if;
        when DECODING_NIR =>
            if pixels_available = '1' then
                increment_sum(pixels, sum_row, counters);
                increment_counters(counters, window_sizes.nir);
                if (counters.pixel = 0 and counters.row = 0) then
                    sum_to_average(sum_row, window_sizes.nir, rows.nir);
                    reset(counters, sum_row);
                    state := IDLE;
                    rows_available <= '1';
                end if;
            end if;
        end case;
    end process;
end architecture rtl;
