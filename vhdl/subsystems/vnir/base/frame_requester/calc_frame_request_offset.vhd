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


-- Calculates the offset (in clocks) between the exposure_start signal and the
-- frame_request signal. According section 5.1 of the user manual, this is almost
-- (but not quite) the same as the exposure time.
--
-- The exposure time in sensor clocks is given by the equation:
--
--               exposure_time = 129*0.43*20 + frame_request_offset
--                             < 1110 + frame_request_offset
--
-- which allows us to go backward from the desired exposure time to get the
-- needed frame request offset.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;





entity calc_frame_request_offset is
generic (
    CLOCKS_PER_SEC  : integer;
    SCLOCKS_PER_SEC : integer;
    FRAGMENT_WIDTH  : integer
);
port (
    clock           : in std_logic;
    reset_n         : in std_logic;

    fps             : in integer;
    exposure_time   : in integer;

    start           : in std_logic;
    done            : out std_logic;

    offset          : out integer
);
end entity calc_frame_request_offset;


architecture rtl of calc_frame_request_offset is

    component idivide is
    generic (
        N_CLOCKS : integer;
        NUMERATOR_BITS : integer;
        DENOMINATOR_BITS : integer
    );
    port (
        clock   : in std_logic;
        reset_n : in std_logic;
        n       : in integer;
        d       : in integer;
        q       : out integer;
        start   : in std_logic;
        done    : out std_logic
    );
    end component idivide;


    component imultiply is
    generic (
        N_CLOCKS : integer
    );
    port (
        clock   : in std_logic;
        reset_n : in std_logic;
        a       : in integer;
        b       : in integer;
        p       : out integer;
        start   : in std_logic;
        done    : out std_logic
    );
    end component imultiply;

    constant CLOCKS_PER_SCLOCKS : real := real(CLOCKS_PER_SEC) / real(SCLOCKS_PER_SEC);
    constant EXTRA_EXPOSURE_CLOCKS : integer := integer(
        129.0 * 0.43 * 20.0 * CLOCKS_PER_SCLOCKS * 0.0
    );
    constant FOT_CLOCKS : integer := integer(
        (20.0 + 2.0 * 16.0 / real(FRAGMENT_WIDTH)) * CLOCKS_PER_SCLOCKS
    );

    signal clocks_per_frame : integer;
    signal done_clocks_per_frame : std_logic;
    
    signal clocks_per_exposure_1000 : integer;
    signal done_clocks_per_exposure_1000 : std_logic;

    signal clocks_per_exposure : integer;
    signal done_clocks_per_exposure : std_logic;
    
begin

    calc_clocks_per_frame : idivide generic map (5, 32, 11) port map (
        clock => clock, reset_n => reset_n,
        n => CLOCKS_PER_SEC, d => fps,
        q => clocks_per_frame,
        start => start, done => done_clocks_per_frame
    );

    calc_clocks_per_exposure_1000 : imultiply generic map (1) port map (
        clock => clock, reset_n => reset_n,
        a => CLOCKS_PER_SEC, b => exposure_time,
        p => clocks_per_exposure_1000,
        start => start, done => done_clocks_per_exposure_1000
    );

    calc_clocks_per_exposure : idivide generic map (4, 32, 11) port map (
        clock => clock, reset_n => reset_n,
        n => clocks_per_exposure_1000, d => 1000,
        q => clocks_per_exposure,
        start => done_clocks_per_exposure_1000, done => done_clocks_per_exposure
    );

    process
    begin
        wait until rising_edge(clock);
        done <= done_clocks_per_exposure;
        if done_clocks_per_exposure = '1' then
            offset <= clocks_per_exposure - EXTRA_EXPOSURE_CLOCKS;
        end if;
    end process;

end architecture rtl;
