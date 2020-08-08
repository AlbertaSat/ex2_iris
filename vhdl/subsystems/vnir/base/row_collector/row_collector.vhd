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

use work.integer_types.all;

use work.vnir_base.all;
use work.row_collector_pkg.all;

entity row_collector is
generic (
    ROW_WIDTH           : integer;
    FRAGMENT_WIDTH      : integer;
    PIXEL_BITS          : integer;
    N_WINDOWS           : integer range 1 to MAX_N_WINDOWS;
    SUM_BITS            : integer := 21  -- 2048 10-bit integers added together take 21 bits.
);
port (
    clock               : in std_logic;
    reset_n             : in std_logic;

    config              : in config_t;
    read_config         : in std_logic;

    start               : in std_logic;
    done                : out std_logic;

    fragment            : in fragment_t;
    fragment_available  : in std_logic;

    row                 : out row_t;
    row_window          : out integer
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

    constant ADDRESS_BITS : integer := 20;
    subtype address_t is std_logic_vector(ADDRESS_BITS-1 downto 0);

    subtype sum_pixel_t is std_logic_vector(SUM_BITS-1 downto 0);
    type sum_pixel_vector_t is array(integer range <>) of sum_pixel_t;

    pure function to_sum_pixel(u : unsigned) return sum_pixel_t is
        variable p : sum_pixel_t;
    begin
        p := (others => '0');
        p(u'range) := std_logic_vector(u);
        return p;
    end function to_sum_pixel;

    pure function to_sum_pixels(v : pixel_vector_t) return sum_pixel_vector_t is
        variable ret : sum_pixel_vector_t(v'range);
    begin
        for i in v'range loop
            ret(i) := to_sum_pixel(v(i));
        end loop;
        return ret;
    end function to_sum_pixels;

    pure function "+" (lhs : sum_pixel_vector_t; rhs : sum_pixel_vector_t) return sum_pixel_vector_t is
        variable sum : sum_pixel_vector_t(lhs'range);
    begin
        for i in lhs'range loop
            sum(i) := std_logic_vector(unsigned(lhs(i)) + unsigned(rhs(i)));
        end loop;
        return sum;
    end function "+";

    pure function "/" (lhs : sum_pixel_vector_t; rhs : integer) return sum_pixel_vector_t is
        variable quotient : sum_pixel_vector_t(lhs'range);
    begin
        for i in lhs'range loop
            quotient(i) := std_logic_vector(unsigned(lhs(i)) / to_unsigned(rhs, lhs'length));
        end loop;
        return quotient;
    end function "/";

    pure function to_pixel(p : sum_pixel_t) return pixel_t is
    begin
        return pixel_t(p(PIXEL_BITS-1 downto 0));  -- TODO: fix this
    end function to_pixel;

    pure function to_pixels(v : sum_pixel_vector_t) return pixel_vector_t is
        variable ret : pixel_vector_t(v'range)(PIXEL_BITS-1 downto 0);  -- TODO: fix this
    begin
        for i in v'range loop
            ret(i) := to_pixel(v(i));
        end loop;
        return ret;
    end function to_pixels;

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
            row_index_range := max(index.rows_per_window);
            row_index := x_pos(index, windows) rem row_index_range;
            address_i :=  row_index_range * index.fragments_per_row * index.window
                        + index.fragments_per_row * row_index
                        + index.fragment;
            return to_address(address_i);
        end function to_address;

    -- Pipeline stage 0 output
    signal fragment_p0 : fragment_t(FRAGMENT_WIDTH-1 downto 0)(PIXEL_BITS-1 downto 0);
    signal index_p0 : fragment_idx_t;
    signal p0_done : std_logic;
    -- Pipeline stage 1 output
    signal fragment_p1 : fragment_t(FRAGMENT_WIDTH-1 downto 0)(PIXEL_BITS-1 downto 0);
    signal index_p1 : fragment_idx_t;
    signal p1_done : std_logic;
    -- Pipeline stage 2 output
    signal fragment_p2 : fragment_t(FRAGMENT_WIDTH-1 downto 0)(PIXEL_BITS-1 downto 0);
    signal index_p2 : fragment_idx_t;
    signal p2_done : std_logic;

    -- RAM signals
    signal read_data : sum_pixel_vector_t(FRAGMENT_WIDTH-1 downto 0);
    signal read_address : address_t;
    signal read_enable : std_logic;
    signal write_data : sum_pixel_vector_t(FRAGMENT_WIDTH-1 downto 0);
    signal write_address : address_t;
    signal write_enable : std_logic;

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
            if start = '1' then
                index := initial_index(windows);
                max_x := image_length - 1;
            end if;
            if fragment_available = '1' then
                -- Filter out rows outside of image boundaries
                x := x_pos(index, windows);
                if 0 <= x and x <= max_x then
                    -- Make previous sum available for next pipeline stage
                    if index.row > 0 then
                        read_address <= to_address(index, windows);
                        read_enable <= '1';
                    end if;
                    -- Advance to next pipeline stage
                    fragment_p0 <= fragment;
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
        variable sum : sum_pixel_vector_t(fragment_p1'range);
    begin
        wait until rising_edge(clock);

        p2_done <= '0';
        write_enable <= '0';
        write_address <= (others => '0');  -- Get rid of some annoying warnings

        if reset_n = '1' then
            if p1_done = '1' then
                -- Add to running sum
                if index_p1.row = 0 then
                    sum := to_sum_pixels(fragment_p1);
                else
                    sum := to_sum_pixels(fragment_p1) + read_data;
                end if;

                -- Write new running sum to RAM
                write_address <= to_address(index_p1, windows);
                write_data <= sum;
                write_enable <= '1';

                -- If this is the last row of the window, compute the average from the sum
                if is_last_row(index_p1) then
                    fragment_p2 <= to_pixels(sum / window_size(index_p1));
                    index_p2 <= index_p1;
                    p2_done <= '1';
                end if;
            end if;
        end if;
    end process p2;

    -- Pipeline stage 3: collect the averaged fragments from the previous pipeline stage into
    -- rows.
    p3 : process
        variable offset : integer;
        variable stride : integer;
        variable n_rows : integer_vector_t(2 downto 0);
        variable n_rows_target : integer_vector_t(2 downto 0);
    begin
        wait until rising_edge(clock);

        row_window <= -1;
        done <= '0';

        if reset_n = '1' then
            if start = '1' then
                n_rows := (others => 0);
                n_rows_target := (others => image_length);
            elsif p2_done = '1' then
                offset := index_p2.fragment;
                stride := index_p2.fragments_per_row;
                for i in fragment_p2'range loop
                    row(offset + i * stride) <= fragment_p2(i);
                end loop;
                if is_last_fragment(index_p2) then
                    row_window <= index_p2.window;
                    n_rows(index_p2.window) := n_rows(index_p2.window) + 1;
                    if n_rows = n_rows_target then
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
