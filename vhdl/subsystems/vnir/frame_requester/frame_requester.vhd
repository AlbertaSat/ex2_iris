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
use work.frame_requester_pkg.all;

entity frame_requester is
generic (
    clocks_per_sec      : integer
);
port (
    -- Interface w/ subsystems is clocked on the main clock
    clock               : in std_logic;
    reset_n             : in std_logic;

    config              : in frame_requester_config_t;
    start_config        : in std_logic;
    config_done         : out std_logic;
    
    do_imaging          : in std_logic;
    imaging_done        : out std_logic;
    
    -- Interface w/ sensor is clocked on the sensor clock
    sensor_clock        : in std_logic;
    frame_request       : out std_logic;
    exposure_start      : out std_logic
);
end entity frame_requester;

architecture rtl of frame_requester is

    component frame_requester_sensor_clock is
    generic (
        clocks_per_sec      : integer
    );
    port (
        sensor_clock        : in std_logic;
        reset_n             : in std_logic;
        config              : in frame_requester_config_t;
        start_config        : in std_logic;
        config_done         : out std_logic;
        do_imaging          : in std_logic;
        imaging_done        : out std_logic;
        frame_request       : out std_logic;
        exposure_start      : out std_logic
    );
    end component frame_requester_sensor_clock;

    component cmd_cross_clock is
    port (
        reset_n   : in std_logic;
        i_clock   : in std_logic;
        i         : in std_logic;
        o_clock   : in std_logic;
        o         : out std_logic;
        o_reset_n : out std_logic
    );
    end component cmd_cross_clock;

    signal reset_n_sensor_clock         : std_logic;
    signal start_config_sensor_clock    : std_logic;
    signal config_done_sensor_clock     : std_logic;
    signal do_imaging_sensor_clock      : std_logic;
    signal imaging_done_sensor_clock    : std_logic;
    
begin

    ir_sensor_clock_component : frame_requester_sensor_clock generic map (
        clocks_per_sec => 48000000
    ) port map (
        sensor_clock => sensor_clock,
        reset_n => reset_n_sensor_clock,
        
        config => config,
        start_config => start_config_sensor_clock,
        config_done => config_done_sensor_clock,
        
        do_imaging => do_imaging_sensor_clock,
        imaging_done => imaging_done_sensor_clock,
        
        frame_request => frame_request,
        exposure_start => exposure_start
    );

    -- Translate reset_n to sensor clock domain
    reset_n_clock_bridge : cmd_cross_clock port map (
        reset_n => reset_n,
        i_clock => clock,
        i => '0',
        o_clock => sensor_clock,
        o => open,
        o_reset_n => reset_n_sensor_clock
    );

    -- Translate start_config to sensor clock domain
    start_config_clock_bridge : cmd_cross_clock port map (
        reset_n => reset_n,
        i_clock => clock,
        i => start_config,
        o_clock => sensor_clock,
        o => start_config_sensor_clock,
        o_reset_n => open
    );

    -- Translate config_done from sensor clock domain
    config_done_clock_bridge : cmd_cross_clock port map (
        reset_n => reset_n,
        i_clock => clock,
        i => config_done_sensor_clock,
        o_clock => sensor_clock,
        o => config_done,
        o_reset_n => open
    );

    -- Translate do_imaging to sensor clock domain
    do_imaging_clock_bridge : cmd_cross_clock port map (
        reset_n => reset_n,
        i_clock => clock,
        i => do_imaging,
        o_clock => sensor_clock,
        o => do_imaging_sensor_clock,
        o_reset_n => open
    );

    -- Translate imaging_done from sensor clock domain
    imaging_done_clock_bridge : cmd_cross_clock port map (
        reset_n => reset_n,
        i_clock => clock,
        i => imaging_done_sensor_clock,
        o_clock => sensor_clock,
        o => imaging_done,
        o_reset_n => open
    );


    

end architecture rtl;
