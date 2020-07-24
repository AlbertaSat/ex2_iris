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

entity frame_requester_sensor_clock is
generic (
    clocks_per_sec      : integer
);
port (
    -- All signals clocked on the sensor clock
    sensor_clock        : in std_logic;
    reset_n             : in std_logic;
    
    config              : in vnir_config_t;
    image_config        : in vnir_image_config_t;
    start_config        : in std_logic;
    config_done         : out std_logic;
    
    do_imaging          : in std_logic;
    image_length        : out integer;
    imaging_done        : out std_logic;
    
    frame_request       : out std_logic;
    exposure_start      : out std_logic
);
end entity frame_requester_sensor_clock;

architecture rtl of frame_requester_sensor_clock is

    -- How many rows does are image have?
    pure function calc_image_length(config : vnir_image_config_t) return integer is
    begin
        return config.fps * config.duration / 1000;
    end function calc_image_length;
    
    pure function calc_num_frames(config : vnir_config_t; image_config : vnir_image_config_t) return integer is
    begin
        -- TODO: it's cleaner here if we do something like max(config.windows.hi)
        return calc_image_length(image_config) + config.window_red.hi; 
    end function calc_num_frames;

    -- Calculates the offset (in clocks) between the exposure_start signal and the
    -- frame_request signal. According section 5.1 of the user manual, this is almost
    -- (but not quite) the same as the exposure time.
    --
    -- The exposure time in clocks is given by the equation:
    --
    --               exposure_time = 129*0.43*20 + frame_request_offset
    --                             < 1110 + frame_request_offset
    --
    -- which allows us to go backward from the desired exposure time to get the
    -- needed frame request offset.
    pure function calc_frame_request_offset(image_config : vnir_image_config_t) return integer is
        constant extra_exposure_time : integer := 1110;
        constant clocks_per_fot : integer := 20 + 2 * 16 / vnir_lvds_n_channels;
        variable clocks_per_frame : integer;
        variable clocks_per_exposure : integer;
        variable frame_request_offset : integer;
    begin
        clocks_per_frame := clocks_per_sec / image_config.fps;
        clocks_per_exposure := clocks_per_sec * image_config.exposure_time / 1000;
        frame_request_offset := clocks_per_exposure - extra_exposure_time;
        
        if frame_request_offset <= 0 then
            report "Can't compute frame_request_offset: requested exposure is too low" severity failure;
            return 1;
        end if;
        
        if frame_request_offset + clocks_per_fot > clocks_per_frame then
            report "Can't compute frame_request_offset: requested exposure is too high" severity failure;
            return clocks_per_frame - clocks_per_fot;
        end if;
        
        return frame_request_offset;
            
    end function calc_frame_request_offset;

begin

    fsm : process
        type state_t is (RESET, IDLE, IMAGING);
        variable state : state_t;

        variable frame_request_gen : pulse_generator_t;
        variable exposure_start_gen : pulse_generator_t;
        variable config_v : vnir_config_t;
    begin
        wait until rising_edge(sensor_clock);

        config_done <= '0';
        imaging_done <= '0';

        if reset_n = '0' then
            frame_request_gen := pulse_generator_new;
            exposure_start_gen := pulse_generator_new;
            state := RESET;
        end if;

        step(frame_request_gen);
        step(exposure_start_gen);
        frame_request <= frame_request_gen.pulses_out;
        exposure_start <= exposure_start_gen.pulses_out;

        case state is
        when RESET =>
            image_length <= 0;
            state := IDLE;
        when IDLE =>
            if start_config = '1' then
                frame_request_gen := pulse_generator_new (
                    image_config.fps,
                    calc_frame_request_offset(image_config),                
                    calc_num_frames(config, image_config),
                    clocks_per_sec
                );
                exposure_start_gen := pulse_generator_new (
                    image_config.fps,
                    0,
                    calc_num_frames(config, image_config),
                    clocks_per_sec
                );
                image_length <= calc_image_length(image_config);
                config_done <= '1';
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

end architecture rtl;
