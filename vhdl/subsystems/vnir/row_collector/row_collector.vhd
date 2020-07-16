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

use work.vnir_types.all;
use work.row_collector_pkg.all;
use work.integer_types.all;

entity row_collector is
port (
    clock               : in std_logic;

    config              : in vnir_config_t;
    read_config         : in std_logic;

    start               : in std_logic;

    fragment            : in fragment_t;
    fragment_available  : in std_logic;

    rows                : out vnir_rows_t;
    rows_available      : out std_logic
);
end entity row_collector;


architecture rtl of row_collector is

    component row_buffer is
    generic (
        word_size : integer;
        address_size : integer
    );
    port (
        clock           : in std_logic;
        read_data       : out std_logic_vector(word_size-1 downto 0);
        read_address    : in std_logic_vector(address_size-1 downto 0);
        write_data      : in std_logic_vector(word_size-1 downto 0);
        write_address   : in std_logic_vector(address_size-1 downto 0);
        write_enable    : in std_logic
    );
    end component row_buffer;

    type vnir_window_vector_t is array (integer range <>) of vnir_window_t;

    constant address_bits : integer := 9;
    subtype address_t is std_logic_vector(address_bits-1 downto 0);

    constant sum_bits : integer := 21;  -- 2048 10-bit integers added together take 21 bits.
    subtype sum_pixel_t is std_logic_vector(sum_bits-1 downto 0);
    type sum_pixel_vector_t is array(integer range <>) of sum_pixel_t;

    pure function sizes(windows : vnir_window_vector_t) return integer_vector_t is
        variable sizes : integer_vector_t(windows'range);
    begin
        for i in windows'range loop
            sizes(i) := size(windows(i));
        end loop;
        return sizes;
    end function sizes;

    pure function initial_index(windows : vnir_window_vector_t) return fragment_idx_t is
        variable index : fragment_idx_t;
    begin
        index := (
            fragment => 0, row => 0, window => 0, frame => 0,
            fragments_per_row => vnir_row_width / vnir_lvds_n_channels,
            rows_per_window => sizes(windows),
            windows_per_frame => 3
        );
        return index;
    end function initial_index;

    pure function x_pos(index : fragment_idx_t; windows : vnir_window_vector_t) return integer is
    begin
        return index.frame - windows(index.window).lo + windows(0).lo - index.row;
    end function x_pos;

    pure function to_address(i : integer) return address_t is
    begin
        return std_logic_vector(to_unsigned(i, address_bits));
    end function to_address;

    pure function to_address(index : fragment_idx_t; windows : vnir_window_vector_t) return address_t is
        variable row_position : integer;
        variable row_index : integer;
        variable address_i : integer;
    begin
        assert x_pos(index, windows) >= 0;
        row_index := x_pos(index, windows) rem max(index.rows_per_window);
        address_i :=  max(index.rows_per_window) * index.window
                    + index.fragments_per_row * row_index
                    + index.fragment;
        return to_address(address_i);
    end function to_address;

    pure function to_sum_pixel(u : unsigned) return sum_pixel_t is
        variable p : sum_pixel_t;
    begin
        p := (others => '0');
        p(u'length-1 downto 0) := std_logic_vector(u);
        return p;
    end function to_sum_pixel;

    pure function to_sum_pixels(v : vnir_pixel_vector_t) return sum_pixel_vector_t is
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

    pure function to_vnir_pixel(p : sum_pixel_t) return vnir_pixel_t is
    begin
        return vnir_pixel_t(p(vnir_pixel_bits-1 downto 0));
    end function to_vnir_pixel;

    pure function to_vnir_pixels(v : sum_pixel_vector_t) return vnir_pixel_vector_t is
        variable ret : vnir_pixel_vector_t(v'range);
    begin
        for i in v'range loop
            ret(i) := to_vnir_pixel(v(i));
        end loop;
        return ret;
    end function to_vnir_pixels;

    -- Pipeline stage 0 output
    signal fragment_p0 : fragment_t;
    signal index_p0 : fragment_idx_t;
    signal p0_done : std_logic;
    -- Pipeline stage 1 output
    signal fragment_p1 : fragment_t;
    signal index_p1 : fragment_idx_t;
    signal p1_done : std_logic;
    -- Pipeline stage 2 output
    signal fragment_p2 : fragment_t;
    signal index_p2 : fragment_idx_t;
    signal p2_done : std_logic;

    -- RAM signals
    signal read_data : sum_pixel_vector_t(vnir_lvds_n_channels-1 downto 0);
    signal read_address : address_t;
    signal write_data : sum_pixel_vector_t(vnir_lvds_n_channels-1 downto 0);
    signal write_address : address_t;
    signal write_enable : std_logic;

    signal windows : vnir_window_vector_t(2 downto 0);

begin

    config_process : process
    begin
        wait until rising_edge(clock);
        if read_config = '1' then
            windows <= (
                0 => config.window_nir,
                1 => config.window_blue,
                2 => config.window_red
            );
        end if;
    end process config_process;

    -- Pipeline stage 0: calculate fragment indices (fragment #, row #, etc.)
    p0 : process
        variable index : fragment_idx_t;
    begin
        wait until rising_edge(clock);
        
        p0_done <= '0';

        if start = '1' then
            index := initial_index(windows);
        end if;
        if fragment_available = '1' then
            fragment_p0 <= fragment;
            index_p0 <= index;
            p0_done <= '1';
            increment(index);
        end if;
    end process p0;

    -- Pipeline stage 1: request the last value of the sum corresponding to this fragment
    p1 : process
    begin
        wait until rising_edge(clock);

        p1_done <= '0';

        if p0_done = '1' and x_pos(index_p0, windows) >= 0 then
            read_address <= to_address(index_p0, windows);
            fragment_p1 <= fragment_p0;
            index_p1 <= index_p0;
            p1_done <= '1';
        end if;
    end process p1;

    -- Pipeline stage 2: read in the sum requested in pipeline stage 2, and update it
    -- by adding this fragment to it. Write the result back into RAM. Possibly compute the
    -- average from the sum and export it to the next pipeline stage.
    p2 : process
        variable sum : sum_pixel_vector_t(fragment_p1'range);
    begin
        wait until rising_edge(clock);

        write_enable <= '0';
        p2_done <= '0';

        if p1_done = '1' then
            -- Write to RAM
            if index_p1.row = 0 then
                sum := to_sum_pixels(fragment_p1);
            else
                sum := to_sum_pixels(fragment_p1) + read_data;
            end if;
            write_address <= to_address(index_p1, windows);
            write_data <= sum;
            write_enable <= '1';

            -- Average
            if is_last_row(index_p1) then
                fragment_p2 <= to_vnir_pixels(sum / window_size(index_p1));
                index_p2 <= index_p1;
                p2_done <= '1';
            end if;
        end if;
    end process p2;

    -- Pipeline stage 3: collect the averaged fragments from the previous pipeline stage into
    -- rows. When a row of each colour has been recieved, export the rows to the "rows" port,
    -- asserting "rows_available".
    p3 : process
        variable row : vnir_row_t;
        variable offset : integer;
        variable stride : integer;
    begin
        wait until rising_edge(clock);

        rows_available <= '0';

        if p2_done = '1' then
            offset := index_p2.fragment;
            stride := index_p2.fragments_per_row;
            for i in fragment_p2'range loop
                row(offset + i * stride) := fragment_p2(i);
            end loop;
            if is_last_fragment(index_p2) then
                case index_p2.window is
                    when 0 => rows.nir <= row;
                    when 1 => rows.blue <= row;
                    when 2 => rows.red <= row;
                    when others =>
                        report "Invalid row detected in row_averager.p3" severity failure;
                end case;
                if is_last_window(index_p2) then
                    rows_available <= '1';
                end if;
            end if;
        end if;
    end process p3;

    -- Use multiple RAMs in parallel, so that reading or writing a fragment
    -- takes a single clock cycle
    generate_RAM : for i in 0 to vnir_lvds_n_channels-1 generate

        RAM : row_buffer generic map (
            word_size => sum_bits,
            address_size => address_bits
        ) port map (
            clock => clock,
            read_data => read_data(i),
            read_address => read_address,
            write_data => write_data(i),
            write_address => write_address,
            write_enable => write_enable
        );

    end generate;

end architecture rtl;
