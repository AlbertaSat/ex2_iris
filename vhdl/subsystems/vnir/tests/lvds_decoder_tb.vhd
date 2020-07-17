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

entity lvds_decoder_tb is
end entity lvds_decoder_tb;

architecture tests of lvds_decoder_tb is
    constant out_dir : string := "../subsystems/vnir/tests/out/lvds_decoder/";

    type state_t is (IDLE, TRANSMIT);
    signal state : state_t;

    subtype word_t is std_logic_vector(vnir_pixel_bits-1 downto 0);
    type word_vector_t is array(integer range <>) of word_t;
    subtype lvds_data_t is word_vector_t(vnir_lvds_n_channels-1 downto 0);
    type lvds_data_vector_t is array(integer range <>) of lvds_data_t;

    -- TODO: I think this is wrong
    constant control_idle : word_t := (vnir_pixel_bits-10 => '1', others => '0');
    constant control_readout : word_t := (vnir_pixel_bits-1 => '1', others => '0');

    signal data_idle : lvds_data_t;
    signal data_transmit : lvds_data_vector_t(10-1 downto 0);

    procedure read(file f : text; data : out lvds_data_t) is
        variable f_line : line;
    begin
        assert not endfile(f);
        readline(f, f_line);
        for i in data'range loop
            read(f_line, data(i));
        end loop;
    end procedure read;

    procedure read(file f : text; data_v : out lvds_data_vector_t) is
    begin
        for i in data_v'range loop
            read(f, data_v(i));
        end loop;
    end procedure read;

    pure function to_word(u : unsigned) return word_t is
        variable w : word_t;
    begin
        for i in w'range loop
            w(i) := u(i);
        end loop;
        return w;
    end function to_word;

    constant lvds_clock_period : time := 4.167 ns;
    constant clock_period : time := 20 ns;

    signal clock : std_logic := '0';
    signal reset_n : std_logic := '0';
    signal start_align : std_logic := '0';
    signal align_done : std_logic;
    signal lvds : vnir_lvds_t := (
        clock => '0', 
        control => '0',
        data => (others => '0')
    );
    signal parallel_out : vnir_parallel_lvds_t;
    signal data_available : std_logic;

    procedure lvds_transmit(
        control : in word_t;
        data : in word_vector_t;
        signal lvds : inout vnir_lvds_t
    ) is
    begin
        for i in control'range loop
            lvds.control <= control(i);
            for j in data'range loop
                lvds.data(j) <= data(j)(i);
            end loop;
            wait for lvds_clock_period / 2;
            lvds.clock <= not lvds.clock;
        end loop;
    end procedure lvds_transmit;

    component lvds_decoder is
    port (
        clock          : in std_logic;
        reset_n        : in std_logic;
        start_align    : in std_logic;
        align_done     : out std_logic;
        lvds_in        : in vnir_lvds_t;
        parallel_out   : out vnir_parallel_lvds_t;
        data_available : out std_logic
    );
    end component lvds_decoder;
begin
    
    clock_process : process
    begin
        wait for clock_period / 2;
        clock <= not clock;
    end process clock_process;
    
    init_process : process
        file data_idle_file : text open read_mode is out_dir & "data_idle.out";
        file data_transmit_file : text open read_mode is out_dir & "data_transmit.out";
        variable d : lvds_data_t;
        variable d_v : lvds_data_vector_t(data_transmit'range);
    begin
         wait until rising_edge(clock);
         read(data_idle_file, d); data_idle <= d;
         read(data_transmit_file, d_v); data_transmit <= d_v;
         wait;
    end process init_process;

    lvds_out_process : process
    begin
        case state is
        when IDLE =>
            lvds_transmit(control_idle, data_idle, lvds);
        when TRANSMIT =>
            for word in data_transmit'range loop
                lvds_transmit(control_readout, data_transmit(word), lvds);
            end loop;
        end case;
    end process lvds_out_process;

    tests_process : process
    begin
        state <= IDLE;
        
        wait for 100 ns;
        wait until rising_edge(clock);
        reset_n <= '1';
        
        wait for 100 ns;
        wait until rising_edge(clock);
        
        start_align <= '1'; wait until rising_edge(clock); start_align <= '0';
        wait until rising_edge(clock) and align_done = '1';
        
        for t in 0 to 10 loop  -- Check that we are producing data
            wait until rising_edge(clock) and data_available = '1';
            assert parallel_out.control = to_vnir_control(control_idle) severity failure;
            for i in parallel_out.data'range loop
                assert to_word(parallel_out.data(i)) = data_idle(i) severity failure;
            end loop;
            wait until rising_edge(clock);
        end loop;

        state <= TRANSMIT;
        wait until rising_edge(clock) and data_available = '1' and parallel_out.control = to_vnir_control(control_readout);

        for t in data_transmit'range loop
            assert parallel_out.control = to_vnir_control(control_readout) severity failure;
            for i in parallel_out.data'range loop
                assert to_word(parallel_out.data(i)) = data_transmit(t)(i) severity failure;
            end loop;
            wait until rising_edge(clock) and data_available = '1';
        end loop;

        report "ALL TESTS FINISHED." severity note;

        wait;
    end process tests_process;

    decoder : lvds_decoder port map (
        clock => clock,
        reset_n => reset_n,
        start_align => start_align,
        align_done => align_done,
        lvds_in => lvds,
        parallel_out => parallel_out,
        data_available => data_available
    );

end tests;
