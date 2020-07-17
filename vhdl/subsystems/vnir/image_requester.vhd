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

use work.vnir_types.all;
use work.pulse_generator_pkg.all;

entity image_requester is
generic (
    clocks_per_sec      : integer
);
port (
    clock               : in std_logic;
    reset_n             : in std_logic;
    config              : in vnir_config_t;
    read_config         : in std_logic;
    num_frames          : out integer;
    do_imaging          : in std_logic;
    imaging_done        : out std_logic;
    sensor_clock        : in std_logic;
    frame_request       : out std_logic;
    exposure_start    : out std_logic
);
end entity image_requester;

architecture rtl of image_requester is

    component cmd_cross_clock is
    port (
        reset_n : in std_logic;
        i_clock : in std_logic;
        i       : in std_logic;
        o_clock : in std_logic;
        o       : out std_logic
    );
    end component cmd_cross_clock;

    pure function calc_num_frames(config : vnir_config_t) return integer is
    begin
        return config.fps * config.imaging_duration / 1000;
    end function calc_num_frames;

    pure function calc_frame_request_offset(config : vnir_config_t) return integer is
        variable clocks_per_frame : integer;
        variable clocks_per_exposure : integer;
    begin
        clocks_per_frame := clocks_per_sec / config.fps;
        clocks_per_exposure := clocks_per_sec * config.exposure_time;
        return clocks_per_frame - clocks_per_exposure;
    end function calc_frame_request_offset;

    signal frame_request_main_clock : std_logic;  -- Frame request, main clock domain
    signal exposure_start_main_clock : std_logic; -- Exposure request, main clock domain

begin

    fsm : process
        type state_t is (RESET, IDLE, IMAGING);
        variable state : state_t;

        variable frame_request_gen : pulse_generator_t;
        variable exposure_start_gen : pulse_generator_t;
    begin
        wait until rising_edge(clock);

        if reset_n = '0' then
            frame_request_gen := pulse_generator_new;
            exposure_start_gen := pulse_generator_new;
            state := RESET;
        end if;

        step(frame_request_gen);
        step(exposure_start_gen);
        frame_request_main_clock <= frame_request_gen.pulses_out;
        exposure_start_main_clock <= exposure_start_gen.pulses_out;

        case state is
        when RESET =>
            num_frames <= 0;
            state := IDLE;
        when IDLE =>
            if read_config = '1' then
                -- TODO: frame_request_gen has a phase offset
                frame_request_gen := pulse_generator_new (
                    config.fps,
                    calc_frame_request_offset(config),
                    calc_num_frames(config),
                    clocks_per_sec
                );
                exposure_start_gen := pulse_generator_new (
                    config.fps, 0,
                    calc_num_frames(config),
                    clocks_per_sec
                );
                num_frames <= calc_num_frames(config);
            end if;
            if do_imaging = '1' then
                start(frame_request_gen);
                start(exposure_start_gen);
                state := IMAGING;
            end if;
        when IMAGING =>
            if is_done(frame_request_gen) and is_done(exposure_start_gen) then
                state := IDLE;
                imaging_done <= '1';
            end if;
        end case;
    end process fsm;

    -- Translate frame request to sensor clock domain
    frame_request_clock_bridge : cmd_cross_clock port map (
        reset_n => reset_n,
        i_clock => clock,
        i => frame_request_main_clock,
        o_clock => sensor_clock,
        o => frame_request
    );

    -- Translate exposure request to sensor clock domain
    exposure_start_clock_bridge : cmd_cross_clock port map (
        reset_n => reset_n,
        i_clock => clock,
        i => exposure_start_main_clock,
        o_clock => sensor_clock,
        o => exposure_start
    );

end architecture rtl;
