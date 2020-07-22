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


entity timer is
generic (
    clocks_per_sec  : integer;
    delay_us        : integer
);
port (
    clock   : in std_logic;
    reset_n : in std_logic;
    start   : in std_logic;
    done    : out std_logic
);
end entity timer;


architecture rtl of timer is
begin

    fsm : process
        constant us_per_s : integer := 1000000;
        type state_t is (RESET, IDLE, WAITING);
        variable state : state_t;
        variable clocks_waited : integer;
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
                clocks_waited := 1;
            end if;
        when WAITING =>
            if clocks_waited / (clocks_per_sec / us_per_s) >= delay_us then
                state := IDLE;
                done <= '1';
            end if;
            clocks_waited := clocks_waited + 1;
        end case;
        
    end process fsm;

end architecture rtl;
