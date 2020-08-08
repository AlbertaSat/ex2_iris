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

library std;
use std.env.stop;

use work.spi_types.all;
use work.vnir_base.all;

entity lvds_decoder_tb is
end entity lvds_decoder_tb;

architecture tests of lvds_decoder_tb is
    component lvds_decoder is
    generic (
        FRAGMENT_WIDTH      : integer;
        PIXEL_BITS          : integer
    );
    port (
        clock               : in std_logic;
        reset_n             : in std_logic;
    
        start_align         : in std_logic;
        align_done          : out std_logic;
        
        lvds_data           : in std_logic_vector(FRAGMENT_WIDTH-1 downto 0);
        lvds_control        : in std_logic;
        lvds_clock          : in std_logic;
        
        fragment            : out fragment_t(FRAGMENT_WIDTH-1 downto 0)(PIXEL_BITS-1 downto 0);
        fragment_control    : out control_t;
        fragment_available  : out std_logic
    );
    end component lvds_decoder;
    
    constant FRAGMENT_WIDTH : integer := 16;
    constant PIXEL_BITS : integer := 10;
    constant OUT_DIR : string := "../subsystems/vnir/tests/out/lvds_decoder/";

    type state_t is (IDLE, TRANSMIT);
    signal state : state_t;

    subtype lpixel_t is std_logic_vector(PIXEL_BITS-1 downto 0);
    type lpixel_vector_t is array(integer range <>) of lpixel_t;
    
    subtype lfragment_t is lpixel_vector_t(FRAGMENT_WIDTH-1 downto 0);
    type lfragment_vector_t is array(integer range <>) of lfragment_t;

    procedure read(file f : text; data : out lfragment_t) is
        variable f_line : line;
    begin
        assert not endfile(f);
        readline(f, f_line);
        for i in data'range loop
            read(f_line, data(i));
        end loop;
    end procedure read;

    procedure read(file f : text; data_v : out lfragment_vector_t) is
    begin
        for i in data_v'range loop
            read(f, data_v(i));
        end loop;
    end procedure read;

    pure function to_lpixel(u : unsigned) return lpixel_t is
        variable lpixel : lpixel_t;
    begin
        for i in lpixel'range loop
            lpixel(i) := u(i);
        end loop;
        return lpixel;
    end function to_lpixel;

    constant CONTROL_IDLE    : lpixel_t := (9 => '1', others => '0');
    constant CONTROL_READOUT : lpixel_t := (0 => '1', others => '0');

    signal data_idle     : lfragment_t;
    signal data_transmit : lfragment_vector_t(10-1 downto 0);

    constant LVDS_CLOCK_PERIOD : time := 4.167 ns;
    constant CLOCK_PERIOD      : time := 20 ns;

    signal clock        : std_logic   := '0';
    signal reset_n      : std_logic   := '0';
    
    signal start_align  : std_logic   := '0';
    signal align_done   : std_logic;
    
    signal lvds_clock   : std_logic   := '0';
    signal lvds_control : std_logic := '0';
    signal lvds_data    : std_logic_vector(FRAGMENT_WIDTH-1 downto 0);
    
    signal fragment           : fragment_t(FRAGMENT_WIDTH-1 downto 0)(PIXEL_BITS-1 downto 0);
    signal fragment_control   : control_t;
    signal fragment_available : std_logic;

    procedure lvds_transmit(
        control : in lpixel_t;
        data : in lpixel_vector_t;
        signal lvds_clock : inout std_logic;
        signal lvds_control : inout std_logic;
        signal lvds_data : inout std_logic_vector
    ) is
    begin
        -- Data is sent LSB first
        for i in 0 to control'length-1 loop
            lvds_control <= control(i);
            for j in data'range loop
                lvds_data(j) <= data(j)(i);
            end loop;
            wait for LVDS_CLOCK_PERIOD / 2;
            lvds_clock <= not lvds_clock;
        end loop;
    end procedure lvds_transmit;

begin
    
    clock_process : process
    begin
        wait for CLOCK_PERIOD / 2;
        clock <= not clock;
    end process clock_process;
    
    init_process : process
        file data_idle_file : text open read_mode is OUT_DIR & "data_idle.out";
        file data_transmit_file : text open read_mode is OUT_DIR & "data_transmit.out";
        variable d : lfragment_t;
        variable d_v : lfragment_vector_t(data_transmit'range);
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
            lvds_transmit(CONTROL_IDLE, data_idle, lvds_clock, lvds_control, lvds_data);
        when TRANSMIT =>
            for word in data_transmit'range loop
                lvds_transmit(CONTROL_READOUT, data_transmit(word), lvds_clock, lvds_control, lvds_data);
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
            wait until rising_edge(clock) and fragment_available = '1';
            assert fragment_control = to_control(CONTROL_IDLE) severity failure;
            for i in fragment'range loop
                assert to_lpixel(fragment(i)) = data_idle(i) severity failure;
            end loop;
            wait until rising_edge(clock);
        end loop;

        state <= TRANSMIT;
        wait until rising_edge(clock) and fragment_available = '1' and fragment_control = to_control(CONTROL_READOUT);

        for t in data_transmit'range loop
            assert fragment_control = to_control(CONTROL_READOUT) severity failure;
            for i in fragment'range loop
                assert to_lpixel(fragment(i)) = data_transmit(t)(i) severity failure;
            end loop;
            wait until rising_edge(clock) and fragment_available = '1';
        end loop;

        report "ALL TESTS FINISHED." severity note;
        stop;

    end process tests_process;

    decoder : lvds_decoder generic map (
        FRAGMENT_WIDTH => FRAGMENT_WIDTH,
        PIXEL_BITS => PIXEL_BITS
    ) port map (
        clock => clock,
        reset_n => reset_n,
        start_align => start_align,
        align_done => align_done,
        lvds_data => lvds_data,
        lvds_control => lvds_control,
        lvds_clock => lvds_clock,
        fragment => fragment,
        fragment_control => fragment_control,
        fragment_available => fragment_available
    );

end tests;
