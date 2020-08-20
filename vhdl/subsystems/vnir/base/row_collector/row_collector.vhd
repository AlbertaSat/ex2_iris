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

-- TODO: reset

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.integer_types.all;

use work.vnir_base.all;
use work.row_collector_pkg.all;

entity row_collector is
generic (
    ROW_WIDTH               : integer;
    FRAGMENT_WIDTH          : integer;
    PIXEL_BITS              : integer;
    ROW_PIXEL_BITS          : integer;
    N_WINDOWS               : integer range 1 to MAX_N_WINDOWS;
    METHOD                  : string;
    MAX_WINDOW_SIZE         : integer
);
port (
    clock                   : in std_logic;
    reset_n                 : in std_logic;

    config                  : in config_t;
    read_config             : in std_logic;

    start                   : in std_logic;
    done                    : out std_logic;

    i_fragment              : in pixel_vector_t(FRAGMENT_WIDTH-1 downto 0)(PIXEL_BITS-1 downto 0);
    i_fragment_available    : in std_logic;

    o_fragment              : out pixel_vector_t(FRAGMENT_WIDTH-1 downto 0)(ROW_PIXEL_BITS-1 downto 0);
    o_fragment_window       : out integer;

    status                  : out status_t
);
end entity row_collector;


architecture rtl of row_collector is

    component row_buffer is
    generic (
        WORD_SIZE       : integer;
        ADDRESS_SIZE    : integer
    );
    port (
        clock           : in std_logic;
        read_data       : out std_logic_vector;
        read_address    : in std_logic_vector;
        read_enable     : in std_logic;
        write_data      : in std_logic_vector;
        write_address   : in std_logic_vector;
        write_enable    : in std_logic
    );
    end component row_buffer;

    type lpixel_vector_t is array(integer range <>) of std_logic_vector;

    constant SUM_BITS : integer := integer(ceil(log2(real(2) ** real(PIXEL_BITS) * real(MAX_WINDOW_SIZE))));

    constant ADDRESS_BITS : integer := integer(ceil(log2(real(ROW_WIDTH / FRAGMENT_WIDTH) * real(N_WINDOWS) * real(MAX_WINDOW_SIZE))));
    subtype address_t is std_logic_vector(ADDRESS_BITS-1 downto 0);

    pure function to_pixels(lpixels : lpixel_vector_t) return pixel_vector_t is
        variable pixels : pixel_vector_t(lpixels'range)(lpixels(0)'range);
    begin
        for i in pixels'range loop
            pixels(i) := unsigned(lpixels(i));
        end loop;
        return pixels;
    end function to_pixels;

    pure function to_lpixels(pixels : pixel_vector_t) return lpixel_vector_t is
        variable lpixels : lpixel_vector_t(pixels'range)(pixels(0)'range);
    begin
        for i in lpixels'range loop
            lpixels(i) := std_logic_vector(pixels(i));
        end loop;
        return lpixels;
    end function to_lpixels;

    pure function resize_pixels(pixels : pixel_vector_t; new_size : integer) return pixel_vector_t is
        variable re : pixel_vector_t(pixels'range)(new_size-1 downto 0);
    begin
        for i_pixel in pixels'range loop
            re(i_pixel) := resize(pixels(i_pixel), new_size);
        end loop;
        return re;
    end function resize_pixels;

    pure function "+" (lhs : pixel_vector_t; rhs : pixel_vector_t) return pixel_vector_t is
        variable sum : pixel_vector_t(rhs'range)(rhs(0)'range);
    begin
        for i in lhs'range loop
            sum(i) := lhs(i) + rhs(i);
        end loop;
        return sum;
    end function "+";

    pure function initial_index(windows : window_vector_t) return fragment_idx_t is
        variable index : fragment_idx_t;
    begin
        index := (
            fragment => 0, row => 0, window => 0, frame => 0,
            fragments_per_row => ROW_WIDTH / FRAGMENT_WIDTH,
            rows_per_window => zeros(MAX_N_WINDOWS-windows'length) & sizes(windows),
            windows_per_frame => 3
        );
        return index;
    end function initial_index;

    pure function x_pos(index : fragment_idx_t; windows : window_vector_t) return integer is
    begin
        return index.frame - windows(index.window).lo - index.row;
    end function x_pos;

    pure function to_address(i : integer) return address_t is
    begin
        return std_logic_vector(to_unsigned(i, ADDRESS_BITS));
    end function to_address;

    pure function to_address(index : fragment_idx_t; windows : window_vector_t) return address_t is
        variable row_position : integer;
        variable row_index : integer;
        variable row_index_range : integer;
        variable address_i : integer;
    begin
        assert x_pos(index, windows) >= 0;
        row_index_range := max_n(index.rows_per_window);
        row_index := x_pos(index, windows) rem row_index_range;
        address_i :=  row_index_range * index.fragments_per_row * index.window
                    + index.fragments_per_row * row_index
                    + index.fragment;
        return to_address(address_i);
    end function to_address;

    pure function log2_floor(u : unsigned) return unsigned is
        variable result : unsigned(u'range);
    begin
        for i in 0 to u'length-1 loop
            if u(i) then
                result := to_unsigned(i, result'length);
            end if;
        end loop;
        return result;
    end function log2_floor;

    pure function log2_divide(lhs : unsigned; rhs : unsigned) return unsigned is
        variable quotient : unsigned(lhs'range);
    begin
        assert is_power_of_2(to_integer(rhs));
        quotient := shift_right(lhs, to_integer(log2_floor(rhs)));
        return quotient;
    end function log2_divide;

    pure function log2_divide(lhs : pixel_vector_t; rhs : unsigned) return pixel_vector_t is
        variable quotient : pixel_vector_t(lhs'range)(lhs(0)'range);
    begin
        for i in lhs'range loop
            quotient(i) := pixel_t(log2_divide(unsigned(lhs(i)), rhs));
        end loop;
        return quotient;
    end function log2_divide;

    -- Pipeline stage 0 output
    signal fragment_p0  : pixel_vector_t(FRAGMENT_WIDTH-1 downto 0)(PIXEL_BITS-1 downto 0);
    signal index_p0     : fragment_idx_t;
    signal p0_done      : std_logic;
    -- Pipeline stage 1 output
    signal fragment_p1  : pixel_vector_t(FRAGMENT_WIDTH-1 downto 0)(PIXEL_BITS-1 downto 0);
    signal index_p1     : fragment_idx_t;
    signal p1_done      : std_logic;
    -- Pipeline stage 2 output
    signal fragment_p2  : pixel_vector_t(FRAGMENT_WIDTH-1 downto 0)(ROW_PIXEL_BITS-1 downto 0);
    signal index_p2     : fragment_idx_t;
    signal p2_done      : std_logic;

    -- RAM signals
    signal read_data        : lpixel_vector_t(FRAGMENT_WIDTH-1 downto 0)(SUM_BITS-1 downto 0);
    signal read_address     : address_t;
    signal read_enable      : std_logic;
    signal write_data       : lpixel_vector_t(FRAGMENT_WIDTH-1 downto 0)(SUM_BITS-1 downto 0);
    signal write_address    : address_t;
    signal write_enable     : std_logic;

    signal windows : window_vector_t(N_WINDOWS-1 downto 0);
    signal image_length : integer;

begin

    config_process : process
    begin
        wait until rising_edge(clock);
        if read_config = '1' then
            for i in 0 to N_WINDOWS-2 loop
                assert 0 <= config.windows(i).lo;
                assert config.windows(i).lo <= config.windows(i).hi;
                assert config.windows(i).hi < config.windows(i+1).hi;
                assert config.windows(i+1).hi < 2048;
            end loop;
            
            windows <= config.windows(N_WINDOWS-1 downto 0);
            image_length <= config.image_length;
        end if;
    end process config_process;

    -- Pipeline stage 0: calculate fragment indices (fragment #, row #, etc.).
    -- Filter out any rows that are out of bounds. Request the last value of the
    -- stored sums corresponding to the fragment's location
    p0 : process
        variable index : fragment_idx_t;
        variable max_x : integer;
        variable x : integer;
    begin
        wait until rising_edge(clock);
        
        p0_done <= '0';
        read_enable <= '0';
        read_address <= (others => '0');  -- Get rid of some annoying warnings

        if reset_n = '1' then
            status.i_fragment_available <= i_fragment_available;

            if start = '1' then
                index := initial_index(windows);
                max_x := image_length - 1;
            elsif i_fragment_available = '1' then
                -- Filter out rows outside of image boundaries
                x := x_pos(index, windows);
                status.fragment_x <= x;
                if 0 <= x and x <= max_x then
                    -- Make previous sum available for next pipeline stage
                    if index.row > 0 then
                        read_address <= to_address(index, windows);
                        read_enable <= '1';
                    end if;
                    -- Advance to next pipeline stage
                    fragment_p0 <= i_fragment;
                    index_p0 <= index;
                    p0_done <= '1';
                end if;
                increment(index);
            end if;
        end if;
    end process p0;

    -- Pipeline stage 1: delay until the sum is ready
    p1 : process
    begin
        wait until rising_edge(clock);
        p1_done <= '0';
        if reset_n = '1' and p0_done = '1' then
            fragment_p1 <= fragment_p0;
            index_p1 <= index_p0;
            p1_done <= p0_done;
        end if;
    end process p1;

    -- Pipeline stage 2: read in the sum requested in pipeline stage 0, and update it
    -- by adding this fragment to it. Write the result back into RAM. Possibly compute the
    -- average from the sum and export it to the next pipeline stage.
    p2 : process
        variable sum : pixel_vector_t(fragment_p1'range)(SUM_BITS-1 downto 0);
    begin
        wait until rising_edge(clock);

        p2_done <= '0';
        write_enable <= '0';
        write_address <= (others => '0');  -- Get rid of some annoying warnings

        if reset_n = '1' then
            if p1_done = '1' then
                -- Add to running sum
                if index_p1.row = 0 then
                    sum := resize_pixels(fragment_p1, SUM_BITS);
                else
                    sum := resize_pixels(fragment_p1, SUM_BITS) + to_pixels(read_data);
                end if;

                -- Write new running sum to RAM
                write_address <= to_address(index_p1, windows);
                write_data <= to_lpixels(sum);
                write_enable <= '1';

                -- If this is the last row of the window, compute the average from the sum
                if is_last_row(index_p1) then
                    if METHOD = "SUM" then
                        fragment_p2 <= resize_pixels(sum, ROW_PIXEL_BITS);
                    elsif METHOD = "AVERAGE" then
                        fragment_p2 <= resize_pixels(log2_divide(sum, to_unsigned(window_size(index_p1), 11)), ROW_PIXEL_BITS);
                    else
                        report "Unrecognized METHOD" severity failure;
                    end if;
                    index_p2 <= index_p1;
                    p2_done <= '1';
                end if;
            end if;
        end if;
    end process p2;

    -- Pipeline stage 3: output
    p3 : process
        variable n_rows : integer_vector_t(N_WINDOWS-1 downto 0);
        variable max_rows : integer_vector_t(N_WINDOWS-1 downto 0);
    begin
        wait until rising_edge(clock);

        o_fragment_window <= -1;
        done <= '0';

        if reset_n = '1' then
            if start = '1' then
                n_rows := (others => 0);
                max_rows := (others => image_length);
            elsif p2_done = '1' then
                o_fragment <= fragment_p2;
                o_fragment_available <= index_p2.window;
                if is_last_fragment(index_p2) then
                    n_rows(index_p2.window) := n_rows(index_p2.window) + 1;
                    if n_rows = max_rows then
                        done <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process p3;

    -- Use multiple RAMs in parallel, so that reading or writing a fragment
    -- takes a single clock cycle
    generate_RAM : for i in 0 to FRAGMENT_WIDTH-1 generate

        RAM : row_buffer generic map (
            WORD_SIZE => SUM_BITS,
            ADDRESS_SIZE => ADDRESS_BITS
        ) port map (
            clock => clock,
            read_data => read_data(i),
            read_address => read_address,
            read_enable => read_enable,
            write_data => write_data(i),
            write_address => write_address,
            write_enable => write_enable
        );

    end generate;

end architecture rtl;
