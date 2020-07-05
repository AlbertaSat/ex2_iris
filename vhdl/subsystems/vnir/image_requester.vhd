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

entity image_requester is
generic (
    clocks_per_sec  : integer
);
port (
    clock           : in std_logic;
    reset_n         : in std_logic;
    config          : in vnir_config_t;
    read_config     : in std_logic;
    num_frames      : out integer;
    do_imaging      : in std_logic;
    imaging_done    : out std_logic;
    sensor_clock    : in std_logic;
    frame_request   : out std_logic
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
    end;

    signal frame_request_trigger : std_logic;

begin

    process
        type state_t is (RESET, IDLE, IMAGING);
        variable state : state_t;

        variable frames_remaining : integer;
        variable delay : integer;
        variable fps : integer;
        variable accum_fps : integer;  -- accum * fps
    begin
        wait until rising_edge(clock);

        frame_request_trigger <= '0';
        imaging_done <= '0';

        if reset_n = '0' then
            state := RESET;
        end if;

        case state is
        when RESET =>
            num_frames <= 0;
            frames_remaining := 0;
            state := IDLE;
        when IDLE =>
            if read_config = '1' then
                frames_remaining := calc_num_frames(config);
                fps := config.fps;
                accum_fps := clocks_per_sec;  -- Take first frame immediately
                num_frames <= frames_remaining;
            end if;
            if do_imaging = '1' then
                state := IMAGING;
            end if;
        when IMAGING =>
            if frames_remaining = 0 then
                state := IDLE;
                imaging_done <= '1';
            else
                if accum_fps >= clocks_per_sec then           -- if accum >= clocks_per_frame then
                    accum_fps := accum_fps - clocks_per_sec;  --     accum -= clocks_per_frame
                    frame_request_trigger <= '1';
                    frames_remaining := frames_remaining - 1;
                end if;
                accum_fps := accum_fps + fps;                 -- accum += 1
            end if;
        end case;
    end process;

    u0 : cmd_cross_clock port map (
        reset_n => reset_n,
        i_clock => clock,
        i => frame_request_trigger,
        o_clock => sensor_clock,
        o => frame_request
    );

end architecture rtl;
