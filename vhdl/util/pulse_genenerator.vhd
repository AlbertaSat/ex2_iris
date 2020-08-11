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


entity pulse_generator is
generic (
    CLOCKS_PER_SEC          : integer
);
port (
    clock                   : in std_logic;
    reset_n                 : in std_logic;

    frequency_Hz            : in integer;
    initial_delay_clocks    : in integer;
    n_pulses                : in integer;

    start                   : in std_logic;
    done                    : out std_logic;

    pulses_out              : out std_logic
);
end entity pulse_generator;


architecture rtl of pulse_generator is
begin

    fsm : process
        type state_t is (RESET, IDLE, DELAYING, RUNNING);
        variable state : state_t;
        
        variable pulses_remaining : integer;
        variable delay_remaining : integer;
        variable accum_freq : integer;  -- accum * freq
    begin

        wait until rising_edge(clock);

        if reset_n = '0' then
            state := RESET;
        end if;

        pulses_out <= '0';
        done <= '0';
        
        case state is
        when RESET =>
            state := IDLE;
        when IDLE =>
            if start = '1' then
                pulses_remaining := n_pulses;
                accum_freq := clocks_per_sec;  -- Trigger initial pulse
                delay_remaining := initial_delay_clocks;
                if delay_remaining > 0 then
                    state := DELAYING;
                else
                    state := RUNNING;
                end if;
            end if;
        when DELAYING =>
            if delay_remaining = 1 then
                state := RUNNING;
            end if;
            delay_remaining := delay_remaining - 1;
        when RUNNING =>
            if pulses_remaining = 0 then
                state := IDLE;
                done <= '1';
            elsif accum_freq >= clocks_per_sec then             -- if accum >= clocks_per_pulse then
                accum_freq := accum_freq - clocks_per_sec;      --     accum -= clocks_per_pulse
                pulses_out <= '1';
                pulses_remaining := pulses_remaining - 1;
            end if;
            accum_freq := accum_freq + frequency_hz;            -- accum += 1
        end case;
    end process fsm;

end architecture rtl;
