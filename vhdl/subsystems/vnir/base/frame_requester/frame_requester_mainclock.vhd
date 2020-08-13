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

use work.vnir_base.all;
use work.frame_requester_pkg.all;
use work.unsigned_types.all;
use work.pulse_generator_pkg;

entity frame_requester_mainclock is
generic (
    FRAGMENT_WIDTH      : integer;
    CLOCKS_PER_SEC      : integer;
    MAX_FPS             : integer
);
port (
    clock               : in std_logic;
    reset_n             : in std_logic;
    
    config              : in config_t;
    start_config        : in std_logic;
    config_done         : out std_logic;
    
    do_imaging          : in std_logic;
    imaging_done        : out std_logic;

    status              : out status_t;
    
    frame_request       : out std_logic;
    exposure_start      : out std_logic
);
end entity frame_requester_mainclock;

architecture rtl of frame_requester_mainclock is

    component calc_frame_request_offset is
    generic (
        CLOCKS_PER_SEC  : integer := CLOCKS_PER_SEC;
        SCLOCKS_PER_SEC : integer := 48000000; -- TODO: set this properly
        FRAGMENT_WIDTH  : integer := FRAGMENT_WIDTH;
        MAX_FPS         : integer := MAX_FPS
    );
    port (
        clock           : in std_logic;
        reset_n         : in std_logic;
        fps             : in u64;
        exposure_time   : in u64;
        start           : in std_logic;
        done            : out std_logic;
        offset          : out u64
    );
    end component calc_frame_request_offset;

    component pulse_generator is
    generic (
        CLOCKS_PER_SEC          : integer := CLOCKS_PER_SEC
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
        status                  : out pulse_generator_pkg.status_t
    );
    end component pulse_generator;

    type pulse_gen_config_t is record
        frequency_Hz            : u64;
        initial_delay_clocks    : u64;
        n_pulses                : u64;
    end record pulse_gen_config_t;

    signal frame_request_config     : pulse_gen_config_t;
    signal exposure_start_config    : pulse_gen_config_t;
    signal pulse_gen_start          : std_logic;
    signal pulse_gen_done           : std_logic;

    signal config_reg           : config_t;
    signal calc_offset_start    : std_logic;
    signal calc_offset_done     : std_logic;
    signal frame_request_offset : u64;

begin

    fsm : process
        variable state : state_t;
    begin
        wait until rising_edge(clock);

        calc_offset_start <= '0';
        config_done <= '0';
        imaging_done <= '0';
        pulse_gen_start <= '0';

        if reset_n = '0' then
            state := RESET;
        end if;

        case state is
        when RESET =>
            state := IDLE;
        when IDLE =>
            if start_config = '1' then
                state := CONFIGURING;
                config_reg <= config;
                calc_offset_start <= '1';
            elsif do_imaging = '1' then
                pulse_gen_start <= '1';
                state := IMAGING;
            end if;
        when CONFIGURING =>
            if calc_offset_done = '1' then
                frame_request_config <= (
                    frequency_Hz => to_u64(config_reg.fps),
                    initial_delay_clocks => frame_request_offset,
                    n_pulses => to_u64(config_reg.num_frames)
                );
                exposure_start_config <= (
                    frequency_Hz => to_u64(config_reg.fps),
                    initial_delay_clocks => to_u64(0),
                    n_pulses => to_u64(config_reg.num_frames)
                );
                config_done <= '1';
                state := IDLE;
            end if;
        when IMAGING =>
            if pulse_gen_done = '1' then
                imaging_done <= '1';
            end if;
        end case;

        status.state <= state;
    end process fsm;

    calc_offset : calc_frame_request_offset port map (
        clock => clock,
        reset_n => reset_n,
        fps => to_u64(config_reg.fps),
        exposure_time => to_u64(config_reg.exposure_time),
        start => calc_offset_start,
        done => calc_offset_done,
        offset => frame_request_offset
    );

    frame_request_gen : pulse_generator port map (
        clock => clock,
        reset_n => reset_n,
        frequency_Hz => frame_request_config.frequency_Hz,
        initial_delay_clocks => frame_request_config.initial_delay_clocks,
        n_pulses => frame_request_config.n_pulses,
        start => pulse_gen_start,
        done => pulse_gen_done,
        pulses_out => frame_request,
        status => status.frame_request
    );

    exposure_start_gen : pulse_generator port map (
        clock => clock,
        reset_n => reset_n,
        frequency_Hz => exposure_start_config.frequency_Hz,
        initial_delay_clocks => exposure_start_config.initial_delay_clocks,
        n_pulses => exposure_start_config.n_pulses,
        start => pulse_gen_start,
        done => open,
        pulses_out => exposure_start,
        status => status.exposure_start
    );


end architecture rtl;
