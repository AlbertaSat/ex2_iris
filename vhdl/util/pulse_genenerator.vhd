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



-- package pulse_generator_pkg is
--     type pulse_generator_state_t is (IDLE, DELAYING, RUNNING);

--     type pulse_generator_t is record
--         -- Config
--         frequency_hz : integer;
--         initial_delay : integer;
--         n_pulses : integer;
--         clocks_per_sec : integer;
        
--         -- I/O
--         pulses_out : std_logic;

--         -- State
--         state : pulse_generator_state_t;
--         pulses_remaining : integer;
--         delay_remaining : integer;
--         accum_freq : integer;  -- accum * freq
--     end record pulse_generator_t;

--     pure function pulse_generator_new (
--         frequency_hz : integer := 0;
--         initial_delay : integer := 0;
--         n_pulses : integer := 0;
--         clocks_per_sec : integer := 0
--     ) return pulse_generator_t;

--     procedure start (self : inout pulse_generator_t);
--     procedure step (self : inout pulse_generator_t);

--     pure function is_done (self : pulse_generator_t) return boolean;

--     -- Internal functions, do not use
--     procedure step_delaying (self : inout pulse_generator_t);
--     procedure step_running (self : inout pulse_generator_t);

-- end package pulse_generator_pkg;


-- package body pulse_generator_pkg is
--     pure function pulse_generator_new(
--         frequency_hz : integer := 0;
--         initial_delay : integer := 0;
--         n_pulses : integer := 0;
--         clocks_per_sec : integer := 0
--     ) return pulse_generator_t is
--     begin
--         return (
--             frequency_hz => frequency_hz,
--             initial_delay => initial_delay,
--             n_pulses => n_pulses,
--             clocks_per_sec => clocks_per_sec,
--             pulses_out => '0',
--             state => IDLE,
--             pulses_remaining => 0,
--             delay_remaining => 0,
--             accum_freq => 0
--         );
--     end function pulse_generator_new;

--     procedure start(self : inout pulse_generator_t) is
--     begin
--         self.pulses_remaining := self.n_pulses;
--         self.accum_freq := self.clocks_per_sec;  -- Trigger initial pulse
--         self.delay_remaining := self.initial_delay;
--         if self.delay_remaining > 0 then
--             self.state := DELAYING;
--         else
--             self.state := RUNNING;
--         end if;
--     end procedure start;

--     procedure step(self : inout pulse_generator_t) is
--     begin
--         self.pulses_out := '0';

--         if self.state = DELAYING then
--             step_delaying(self);
--         elsif self.state = RUNNING then
--             step_running(self);
--         end if;
--     end procedure step;

--     pure function is_done (self : pulse_generator_t) return boolean is
--     begin
--         return self.state = IDLE;
--     end function is_done;

--     procedure step_delaying(self : inout pulse_generator_t) is
--     begin
--         if self.delay_remaining = 1 then
--             self.state := RUNNING;
--         end if;
--         self.delay_remaining := self.delay_remaining - 1;
--     end procedure step_delaying;

--     procedure step_running(self : inout pulse_generator_t) is
--     begin
--         if self.pulses_remaining = 0 then
--             self.state := IDLE;
--         else
--             if self.accum_freq >= self.clocks_per_sec then                 -- if accum >= clocks_per_pulse then
--                 self.accum_freq := self.accum_freq - self.clocks_per_sec;  --     accum -= clocks_per_pulse
--                 self.pulses_out := '1';
--                 self.pulses_remaining := self.pulses_remaining - 1;
--             else
--                 self.accum_freq := self.accum_freq + self.frequency_hz;    --     accum += 1
--             end if;
--         end if;
--     end procedure step_running;

-- end package body pulse_generator_pkg;
