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
