library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.sdram_types.all;

entity address_counter is 
    generic(increment_size : integer);
    port(
        clk             : in std_logic;

        start_address   : in sdram_address_t;
        inc_flag        : in std_logic;

        output_address  : out sdram_address_t
    );
end entity address_counter;

architecture rtl of address_counter is
    signal prev_start : sdram_address_t;
    signal count : natural;
begin
    count_process : process (clk) is
    begin
        if rising_edge(clk) then
            if (prev_start /= start_address) then
                --Needs to be set to one to make the next loop work
                count <= 1;
                output_address <= start_address;
            elsif (inc_flag = '1') then
                count <= count + 1;
                output_address <= start_address + (increment_size * count);
            end if;

            prev_start <= start_address;
        end if;
    end process;
end architecture; 