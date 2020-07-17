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
use std.textio.all;

use work.spi_types.all;
use work.vnir_types.all;
use work.test_util.all;

use work.row_collector_pkg.all;


entity row_collector_tb is
end entity row_collector_tb;

architecture tests of row_collector_tb is
    signal clock                : std_logic := '0';
    signal reset_n              : std_logic := '0';
	signal config               : vnir_config_t;
    signal read_config          : std_logic := '0';
    signal start                : std_logic := '0';
    signal image_length         : integer;
    signal fragment             : fragment_t;
	signal fragment_available   : std_logic := '0';
	signal row                  : vnir_row_t;
	signal row_available        : vnir_row_type_t := ROW_NONE;

    component row_collector is
    port (
        clock               : in std_logic;
        reset_n             : in std_logic;
        config              : in vnir_config_t;
        read_config         : in std_logic;
        start               : in std_logic;
        image_length        : in integer;
        fragment            : in fragment_t;
        fragment_available  : in std_logic;
        row                 : out vnir_row_t;
        row_available       : out vnir_row_type_t
    );
    end component row_collector;

    procedure readline(file f : text; row : out vnir_row_t) is
        variable f_line : line;
        variable pixel : integer;
    begin
        readline(f, f_line);
        for i in row'range loop
            read(f_line, pixel);
            row(i) := to_unsigned(pixel, vnir_pixel_bits);
        end loop;
    end procedure readline;

    procedure read(file f : text; config : out vnir_config_t) is
        variable f_line : line;
        variable i : integer;
    begin
        readline(f, f_line);
        read(f_line, config.window_nir.lo);
        read(f_line, config.window_nir.hi);

        readline(f, f_line);
        read(f_line, config.window_blue.lo);
        read(f_line, config.window_blue.hi);
        
        readline(f, f_line);
        read(f_line, config.window_red.lo);
        read(f_line, config.window_red.hi);
    end procedure read;

    procedure read(file f : text; i : out integer) is
        variable f_line : line;
    begin
        readline(f, f_line);
        read(f_line, i);
    end procedure read;

    constant out_dir : string := "../subsystems/vnir/tests/out/row_collector/";

begin

	-- Generate main clock signal
    clock_gen : process
        constant clock_period : time := 20 ns;
	begin
		wait for clock_period / 2;
		clock <= not clock;
	end process clock_gen;

    check_output : process
        variable passed : boolean := true;
        file nir_file : text open read_mode is out_dir & "nir.out";
        file blue_file : text open read_mode is out_dir & "blue.out";
        file red_file : text open read_mode is out_dir & "red.out";
        variable file_row : vnir_row_t;
    begin
        wait until reset_n = '1';

        loop
            wait until rising_edge(clock) and row_available /= ROW_NONE;
            if row_available = ROW_NIR then
                report "Recieved NIR row";
                assert not endfile(nir_file) report "Received extra NIR row" severity failure;
                readline(nir_file, file_row);
                assert row = file_row report "Received mismatched NIR row" severity failure;
            elsif row_available = ROW_BLUE then
                report "Recieved blue row";
                assert not endfile(blue_file) report "Received extra blue row" severity failure;
                readline(blue_file, file_row);
                assert row = file_row report "Received mismatched blue row" severity failure;
            elsif row_available = ROW_RED then
                report "Recieved red row";
                assert not endfile(red_file) report "Received extra red row" severity failure;
                readline(red_file, file_row);
                assert row = file_row report "Received mismatched red row" severity failure;
            end if;

            if endfile(nir_file) and endfile(blue_file) and endfile(red_file) then
                report "Recieved all expected image rows";
            end if;

        end loop;
        
    end process;

    gen_input : process
        constant n_fragments : integer := vnir_row_width / vnir_lvds_n_channels;
        variable tests_passed : boolean := true;
        variable row : vnir_row_t;
        file row_file : text open read_mode is out_dir & "rows.out";
        file window_file : text open read_mode is out_dir & "windows.out";
        file image_length_file : text open read_mode is out_dir & "image_length.out";
        
        variable config_v : vnir_config_t;
        variable image_length_v : integer;
    begin
        read(window_file, config_v);
        read(image_length_file, image_length_v);

        wait until rising_edge(clock);
        reset_n <= '1';
        wait until rising_edge(clock);

        config <= config_v;
        read_config <= '1';
        wait until rising_edge(clock);
        read_config <= '0';

        report "Uploading started";
        image_length <= image_length_v;
        start <= '1';
        wait until rising_edge(clock);
        start <= '0';

        fragment_available <= '1';
        while not endfile(row_file) loop
            readline(row_file, row);

            for f in 0 to n_fragments-1 loop
                for i in 0 to vnir_lvds_n_channels-1 loop
                    fragment(i) <= row(f + n_fragments * i);
                end loop;
                wait until rising_edge(clock);
            end loop;
        end loop;
        fragment_available <= '0';
        report "Uploading finished";
        wait;
    end process;

    row_collector_component : row_collector port map (
        clock => clock,
        reset_n => reset_n,
        config => config,
        read_config => read_config,
        start => start,
        image_length => image_length,
        fragment => fragment,
        fragment_available => fragment_available,
        row => row,
        row_available => row_available
    );

end tests;
