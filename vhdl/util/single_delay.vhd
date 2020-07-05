library ieee;
use ieee.std_logic_1164.all;

entity single_delay is
port (
    clock   : in std_logic;
    reset_n : in std_logic;
    i       : in std_logic;
    o       : out std_logic
);
end entity single_delay;

architecture rtl of single_delay is
begin
    
    process (clock)
    begin
        if rising_edge(clock) then
            if reset_n = '0' then
                o <= '0';
            else
                o <= i;
            end if;
        end if;
    end process;

end architecture rtl;
