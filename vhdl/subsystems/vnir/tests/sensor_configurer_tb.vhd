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

library std;
use std.env.stop;

use work.vnir_types.all;
use work.spi_types.all;
use work.logic_types.all;


entity sensor_configurer_tb is
end entity sensor_configurer_tb;

architecture tests of sensor_configurer_tb is

    component sensor_configurer is
    generic (
        clocks_per_sec      : integer
    );
    port (	
        clock               : in std_logic;
        reset_n             : in std_logic;
        config              : in vnir_config_t;
        start_config        : in std_logic;
        config_done         : out std_logic;
        spi_out             : out spi_from_master_t;
        spi_in              : in spi_to_master_t;
        sensor_power        : out std_logic;
        sensor_clock_enable : out std_logic;
        sensor_reset_n      : out std_logic
    );
    end component sensor_configurer;

    constant clock_period : time := 20 ns;

    signal clock : std_logic := '0';
    signal reset_n : std_logic := '0';
    signal config : vnir_config_t;
    signal start_config : std_logic := '0';
    signal config_done : std_logic;
    signal spi : spi_t;
    signal sensor_power : std_logic;
    signal sensor_clock_enable : std_logic;
    signal sensor_reset_n : std_logic;

    constant n_spi_instructions : integer := 33;
    constant spi_max_addr : integer := 127;

    type reg_t is array (integer range <>) of logic8_t;
    signal reg : reg_t(0 to spi_max_addr);

    procedure check_register_values(reg : in reg_t; config : in vnir_config_t) is
        constant undefined : logic8_t := (others => 'U');
        constant v_ramp1 : integer := 109;
        constant v_ramp2 : integer := 109;
        constant offset : integer := 16323;
        constant adc_gain : integer := 32;
    begin

        for addr in 0 to spi_max_addr loop
            case addr is
                when 0 =>           assert reg(addr) = undefined;
                when 1 =>           assert reg(addr) = to_logic8(total_rows(config));
                when 2 =>           assert reg(addr) = to_logic8(0);
                when 3 =>           assert reg(addr) = to_logic8(config.window_red.lo);
                when 4 =>           assert reg(addr) = to_logic8(0);
                when 5 =>           assert reg(addr) = to_logic8(config.window_blue.lo);
                when 6 =>           assert reg(addr) = to_logic8(0);
                when 7 =>           assert reg(addr) = to_logic8(config.window_nir.lo);
                when 8 =>           assert reg(addr) = to_logic8(0);
                when 9 to 18 =>     assert reg(addr) = undefined;
                when 19 =>          assert reg(addr) = to_logic8(size(config.window_red));
                when 20 =>          assert reg(addr) = to_logic8(0);
                when 21 =>          assert reg(addr) = to_logic8(size(config.window_blue));
                when 22 =>          assert reg(addr) = to_logic8(0);
                when 23 =>          assert reg(addr) = to_logic8(size(config.window_nir));
                when 24 =>          assert reg(addr) = to_logic8(0);
                when 25 to 39 =>    assert reg(addr) = undefined;
                when 40 =>          assert reg(addr) = to_logic8(0);
                when 41 =>          assert reg(addr) = to_logic8(5);
                when 42 to 71 =>    assert reg(addr) = undefined;
                when 72 =>          assert reg(addr) = to_logic8(0);
                when 73 to 76 =>    assert reg(addr) = undefined;
                when 77 =>          assert reg(addr) = to_logic8(0);
                when 78 to 83 =>    assert reg(addr) = undefined;
                when 84 =>          assert reg(addr) = to_logic8(4);
                when 85 =>          assert reg(addr) = to_logic8(1);
                when 86 =>          assert reg(addr) = to_logic8(14);
                when 87 =>          assert reg(addr) = to_logic8(12);
                when 88 =>          assert reg(addr) = to_logic8(64);
                when 89 to 90 =>    assert reg(addr) = undefined;
                when 91 =>          assert reg(addr) = to_logic8(64);
                when 92 to 93 =>    assert reg(addr) = undefined;
                when 94 =>          assert reg(addr) = to_logic8(101);
                when 95 =>          assert reg(addr) = to_logic8(106);
                when 96 to 97 =>    assert reg(addr) = undefined;
                when 98 =>          assert reg(addr) = to_logic8(v_ramp1);
                when 99 =>          assert reg(addr) = to_logic8(v_ramp2);
                when 100 =>         assert reg(addr) = to_logic8(offset);
                when 101 =>         assert reg(addr) = to_logic8(offset / (2**8));
                when 102 =>         assert reg(addr) = to_logic8(1);
                when 103 =>         assert reg(addr) = to_logic8(adc_gain);
                when 104 to 110 =>  assert reg(addr) = undefined;
                when 111 =>         assert reg(addr) = to_logic8(1);
                when 112 =>         assert reg(addr) = to_logic8(0);
                when 113 =>         assert reg(addr) = to_logic8(1) or reg(addr) = undefined;
                when 114 =>         assert reg(addr) = to_logic8(0);
                when 115 =>         assert reg(addr) = to_logic8(0) or reg(addr) = undefined;
                when 116 =>         assert reg(addr)(3 downto 0) = to_logic4(9) and reg(addr)(6 downto 4) = to_logic3(5) and reg(addr)(7) = '1';
                when 117 =>         assert reg(addr) = to_logic8(8);
                when 118 =>         assert reg(addr) = to_logic8(1);
                when 119 to 122 =>  assert reg(addr) = undefined;
                when 123 =>         assert reg(addr) = to_logic8(98);
                when 124 to 127 =>  assert reg(addr) = undefined;
                when others =>      report "Invalid address" severity failure;
            end case;
        end loop;

    end procedure check_register_values;
begin

    clock_gen : process
    begin
        wait for clock_period / 2;
        clock <= not clock;
    end process clock_gen;

    collect_spi_output : process 
        variable word : logic16_t;
        variable i : integer := word'length - 1;
        variable addr : logic7_t;
        variable value : logic8_t;
    begin
        wait until rising_edge(spi.from_master.clock);

        word(i) := spi.from_master.data;
        i := i - 1;
        if (i < 0) then
            addr := word(14 downto 8);
            value := word(7 downto 0);
            reg(to_integer(unsigned(addr))) <= value;
            i := word'length - 1;
        end if;

    end process collect_spi_output;

    test : process
    begin
        wait until rising_edge(clock);
        reset_n <= '1';
        wait until rising_edge(clock);
        
        config.window_nir <= (lo => 11, hi => 15);
        config.window_blue <= (lo => 16, hi => 26);
        config.window_red <= (lo => 30, hi => 50);
        start_config <= '1'; wait until rising_edge(clock); start_config <= '0';
        
        wait for 30 us;
        check_register_values(reg, config);
        report "Finished running tests.";
        stop;

    end process test;

    sensor_configurer_component : sensor_configurer generic map (
        clocks_per_sec => 50000000
    ) port map (
        clock => clock,
        reset_n => reset_n,
        config => config,
        start_config => start_config,
        config_done => config_done,
        spi_out => spi.from_master,
        spi_in => spi.to_master,
        sensor_power => sensor_power,
        sensor_clock_enable => sensor_clock_enable,
        sensor_reset_n => sensor_reset_n
    );

end architecture tests;
