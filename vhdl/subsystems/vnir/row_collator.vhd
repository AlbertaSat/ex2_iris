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
port (
    clock            : in std_logic;
    reset_n          : in std_logic;
    pixels           : in vnir_pixel_vector_t(0 to 4-1);
    pixels_available : in std_logic;
    rows             : out vnir_rows_t;
    rows_available   : out std_logic
);
end entity row_collator;


architecture rtl of row_collator is
    constant pixels_per_row : integer := 512;  -- 2048 / 4

    -- Assumes the maximum window width is 125 pixels.
    constant sum_pixel_bits : integer := 19;  -- ceil(log2(125 * (2 ^ 12 - 1) + 1))
    subtype sum_pixel_t is unsigned(0 to sum_pixel_bits-1);
    type sum_row_t is array(0 to vnir_row_width-1) of sum_pixel_t;  
    type state_t is (IDLE, DECODING_RED, DECODING_BLUE, DECODING_NIR);
    signal state : state_t;

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
        signal pixels : in vnir_pixel_vector_t(0 to 4-1);
        variable sum_row : inout sum_row_t;
        variable counters : in counters_t
    ) is
    begin
        sum_row(counters.pixel + pixels_per_row * 0) := sum_row(counters.pixel + pixels_per_row * 0) + pixels(0);
        sum_row(counters.pixel + pixels_per_row * 1) := sum_row(counters.pixel + pixels_per_row * 1) + pixels(1);
        sum_row(counters.pixel + pixels_per_row * 2) := sum_row(counters.pixel + pixels_per_row * 2) + pixels(2);
        sum_row(counters.pixel + pixels_per_row * 3) := sum_row(counters.pixel + pixels_per_row * 3) + pixels(3);
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
        for i in 0 to 2048-1 loop
            t := sum_row(i) / rows_per_window;
            row(i) <= t(7 to 19-1);
        end loop;
    end procedure sum_to_average;

begin

    main_process : process (clock)
        variable counters : counters_t;
        variable sum_row : sum_row_t;
        variable rows_per_window : integer := 10; -- TODO: set from config
    begin
        if rising_edge(clock) then
            rows_available <= '0';
            if (reset_n = '0') then
                state <= IDLE;
            elsif (pixels_available = '1') then
                case state is
                when IDLE =>
                    state <= DECODING_RED;
                    reset(counters, sum_row);
                    increment_sum(pixels, sum_row, counters);
                    increment_counters(counters, rows_per_window);
                when DECODING_RED =>
                    increment_sum(pixels, sum_row, counters);
                    increment_counters(counters, rows_per_window);
                    if (counters.pixel = 0 and counters.row = 0) then
                        sum_to_average(sum_row, rows_per_window, rows.red);
                        reset(counters, sum_row);
                        state <= DECODING_BLUE;
                    end if;
                when DECODING_BLUE =>
                    increment_sum(pixels, sum_row, counters);
                    increment_counters(counters, rows_per_window);
                    if (counters.pixel = 0 and counters.row = 0) then
                        sum_to_average(sum_row, rows_per_window, rows.blue);
                        reset(counters, sum_row);
                        state <= DECODING_NIR;
                    end if;
                when DECODING_NIR =>
                    increment_sum(pixels, sum_row, counters);
                    increment_counters(counters, rows_per_window);
                    if (counters.pixel = 0 and counters.row = 0) then
                        sum_to_average(sum_row, rows_per_window, rows.nir);
                        reset(counters, sum_row);
                        state <= IDLE;
                        rows_available <= '1';
                    end if;
                end case;
            end if;
        end if;
    end process;
end architecture rtl;
