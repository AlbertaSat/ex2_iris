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
use ieee.math_real.all;

use work.unsigned_types.all;


entity calc_frame_request_offset is
generic (
    CLOCKS_PER_SEC  : integer;
    SCLOCKS_PER_SEC : integer;
    FRAGMENT_WIDTH  : integer;
    MAX_FPS         : integer
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
end entity calc_frame_request_offset;


architecture rtl of calc_frame_request_offset is

    component udivide is
    generic (
        N_CLOCKS : integer;
        NUMERATOR_BITS : integer;
        DENOMINATOR_BITS : integer
    );
    port (
        clock   : in std_logic;
        reset_n : in std_logic;
        n       : in u64;
        d       : in u64;
        q       : out u64;
        start   : in std_logic;
        done    : out std_logic
    );
    end component udivide;


    constant CLOCKS_PER_SCLOCKS : real := real(CLOCKS_PER_SEC) / real(SCLOCKS_PER_SEC);
    constant EXTRA_EXPOSURE_CLOCKS : u64 := to_u64(
        129.0 * 0.43 * 20.0 * CLOCKS_PER_SCLOCKS
    );
    constant FOT_CLOCKS : u64 := to_u64(
        (20.0 + 2.0 * 16.0 / real(FRAGMENT_WIDTH)) * CLOCKS_PER_SCLOCKS
    );

    constant CLOCKS_PER_SEC_BITS : integer := integer(ceil(log2(real(CLOCKS_PER_SEC))));
    constant FPS_BITS : integer := integer(ceil(log2(real(MAX_FPS))));
    constant MUL_BITS : integer := integer(ceil(log2(real(MAX_FPS) * real(CLOCKS_PER_SEC))));

    signal clocks_per_frame : u64;
    signal clocks_per_exposure : u64;
    signal done_clocks_per_exposure : std_logic;

begin

    -- clocks_per_frame <= CLOCKS_PER_SEC / fp
    calc_clocks_per_frame : udivide generic map (5, CLOCKS_PER_SEC_BITS, FPS_BITS) port map (
        clock => clock, reset_n => reset_n,
        n => to_u64(CLOCKS_PER_SEC),
        d => to_u64(fps),
        q => clocks_per_frame,
        start => start, done => open  -- Scheduled to finish at the same time as clocks_per_exposure
    );

    -- clocks_per_exposurer <= CLOCKS_PER_SEC * exposure_time / 1000
    calc_clocks_per_exposure : udivide generic map (5, MUL_BITS, 10) port map (
        clock => clock, reset_n => reset_n,
        n => to_u64(to_u64(CLOCKS_PER_SEC) * exposure_time),
        d => to_u64(1000),
        q => clocks_per_exposure,
        start => start, done => done_clocks_per_exposure
    );

    process
    begin
        wait until rising_edge(clock);
        done <= done_clocks_per_exposure;
        if done_clocks_per_exposure = '1' then
            offset <= clocks_per_exposure - EXTRA_EXPOSURE_CLOCKS;

            if clocks_per_exposure - EXTRA_EXPOSURE_CLOCKS <= 0 then
                report "Can't compute frame_request_offset: requested exposure is too low" severity failure;
                offset <= to_u64(1);
            end if;

            if clocks_per_exposure - EXTRA_EXPOSURE_CLOCKS + FOT_CLOCKS > clocks_per_frame then
                report "Can't compute frame_request_offset: requested exposure is too high" severity failure;
                offset <= to_u64(clocks_per_frame) - FOT_CLOCKS;
            end if;

        end if;
    end process;

end architecture rtl;
