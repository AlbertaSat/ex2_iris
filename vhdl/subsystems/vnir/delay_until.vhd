library ieee;
use ieee.std_logic_1164.all;

entity delay_until is
port (
    clock       : in std_logic;
    reset_n     : in std_logic;
    condition   : in std_logic;
    start       : in std_logic;
    done        : out std_logic
);
end entity delay_until;


architecture rtl of delay_until is
begin
    process
        type state_t is (RESET, IDLE, WAITING);
        variable state : state_t;
    begin
        wait until rising_edge(clock);

        done <= '0';

        if reset_n = '0' then
            state := RESET;
        end if;
        
        case state is
        when RESET =>
            state := IDLE;
        when IDLE =>
            if start = '1' then
                state := WAITING;
            end if;
        when WAITING =>
            if condition = '1' then
                state := IDLE;
                done <= '1';
            end if;
        end case;
        
    end process;
end architecture rtl;
