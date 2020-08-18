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


package pulse_generator_pkg is
    type state_t is (RESET, IDLE, DELAYING, RUNNING);

    type status_t is record
        state   : state_t;
    end record status_t;
end package pulse_generator_pkg;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.pulse_generator_pkg.all;
use work.unsigned_types.all;

-- Produces periodic pulses at a fixed fps
--
-- To use, set `frequency_Hz` to the required fps, `initial_delay_clocks`
-- to the number of clocks to delay before beginning to pulse (i.e. the
-- phase of the resulting waveform), and `n_pulses` to the number of
-- times you want `pulse_generator` to produce an output pulse before
-- returning to it's idle state. Then, assert `start`, and the desired
-- pulses will be produced on the `pulses_out` output. When the
-- `pulse_generator` is finished, it will hold `done` high for a single
-- clock cycle
--
-- `status` contains the current status of the `pulse_generator`, to
-- be used for debugging
entity pulse_generator is
generic (
    CLOCKS_PER_SEC          : integer
);
port (
    clock                   : in std_logic;
    reset_n                 : in std_logic;

    frequency_Hz            : in u64;
    initial_delay_clocks    : in u64;
    n_pulses                : in u64;

    start                   : in std_logic;
    done                    : out std_logic;

    pulses_out              : out std_logic;

    status                  : out status_t
);
end entity pulse_generator;


architecture rtl of pulse_generator is
begin

    fsm : process
        variable state : state_t;
        
        variable pulses_remaining : u64;
        variable delay_remaining : u64;
        variable accum_freq : u64;  -- accum * freq
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
                accum_freq := to_u64(CLOCKS_PER_SEC);  -- Trigger initial pulse
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
            elsif accum_freq >= to_u64(CLOCKS_PER_SEC) then         -- if accum >= clocks_per_pulse then
                accum_freq := accum_freq - to_u64(CLOCKS_PER_SEC);  --     accum -= clocks_per_pulse
                pulses_out <= '1';
                pulses_remaining := pulses_remaining - 1;
            end if;
            accum_freq := accum_freq + frequency_hz;                -- accum += 1
        end case;

        status.state <= state;
    end process fsm;

end architecture rtl;
