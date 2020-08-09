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

    constant CLOCKS_PER_SCLOCKS : real := real(CLOCKS_PER_SEC) / real(SCLOCKS_PER_SEC);
    constant EXTRA_EXPOSURE_CLOCKS : integer := integer(
        129.0 * 0.43 * 20.0 * CLOCKS_PER_SCLOCKS
    );
    constant FOT_CLOCKS : integer := integer(
        (20.0 + 2.0 * 16.0 / real(FRAGMENT_WIDTH)) * CLOCKS_PER_SCLOCKS
    );

    constant CLOCKS_TO_COMPUTE : integer := 5;

    signal fps_in : integer;
    signal exposure_time_in : integer;

    signal clocks_per_frame : integer;
    signal clocks_per_exposure : integer;
    signal offset_out : integer;

    attribute altera_attribute : string;
    attribute altera_attribute of rtl : architecture is "-name SDC_STATEMENT ""set_multicycle_path -from [get_registers *calc_frame_request_offset:*_in*] -to [get_registers *calc_frame_request_offset:*offset*] -setup -end 4; set_multicycle_path -from [get_registers *calc_frame_request_offset:*_in*] -to [get_registers *calc_frame_request_offset:*offset*] -hold -end 4""";

begin

    clocks_per_frame <= CLOCKS_PER_SEC / fps_in;
    clocks_per_exposure <= CLOCKS_PER_SEC * exposure_time_in / 1000;
    offset_out <= clocks_per_exposure - EXTRA_EXPOSURE_CLOCKS;
    
    process
        type state_t is (RESET, IDLE, CALCULATING);
        variable state : state_t;

        variable t : integer;
    begin
        wait until rising_edge(clock);

        done <= '0';

        if reset_n = '0' then
            state := RESET;
        end if;

        case state is
        when RESET => state := IDLE;
        when IDLE =>
            if start = '1' then
                t := 0;
                fps_in <= fps;
                exposure_time_in <= exposure_time;
                state := CALCULATING;
            end if;
        when CALCULATING =>
            if t = CLOCKS_TO_COMPUTE then
                state := IDLE;
                offset <= offset_out;
                done <= '1';
            end if;
            t := t + 1;
        end case;
    
    end process;


end architecture rtl;






-- entity calc_frame_request_offset is
-- generic (
--     CLOCKS_PER_SEC  : integer;
--     SCLOCKS_PER_SEC : integer;
--     FRAGMENT_WIDTH  : integer
-- );
-- port (
--     clock           : in std_logic;
--     reset_n         : in std_logic;

--     fps             : in integer;
--     exposure_time   : in integer;

--     start           : in std_logic;
--     done            : out std_logic;

--     offset          : out integer
-- );
-- end entity calc_frame_request_offset;

-- architecture rtl of calc_frame_request_offset is

--     constant CLOCKS_PER_SCLOCKS : real := real(CLOCKS_PER_SEC) / real(SCLOCKS_PER_SEC);
--     constant EXTRA_EXPOSURE_CLOCKS : integer := integer(
--         129.0 * 0.43 * 20.0 * CLOCKS_PER_SCLOCKS
--     );
--     constant FOT_CLOCKS : integer := integer(
--         (20.0 + 2.0 * 16.0 / real(FRAGMENT_WIDTH)) * CLOCKS_PER_SCLOCKS
--     );

--     signal done_p0 : std_logic;
--     signal fps_p0 : integer;
--     signal exposure_time_p0 : integer;

--     signal done_p1 : std_logic;
--     --signal exposure_time_p1 : integer;
--     signal clocks_per_frame_p1 : integer;

--     signal done_p2 : std_logic;
--     signal clocks_per_exposure_p2 : integer;
--     --signal clocks_per_frame_p2 : integer;

--     signal done_p3 : std_logic;
--     signal frame_request_offset_p3 : integer;
--     --signal clocks_per_frame_p3 : integer;

-- begin

--     p0 : process
--     begin
--         wait until rising_edge(clock);
--         done_p0 <= '0';
--         if reset_n /= '0' and start = '1' then
--             fps_p0 <= fps;
--             exposure_time_p0 <= exposure_time;
--             done_p0 <= '1';
--         end if;
--     end process p0;


--     p1 : process
--     begin
--         wait until rising_edge(clock);
--         done_p1 <= '0';
--         if reset_n /= '0' and done_p0 = '1' then
--             clocks_per_frame_p1 <= CLOCKS_PER_SEC / fps_p0;
--             --exposure_time_p1 <= exposure_time_p0;
--             done_p1 <= '1';
--         end if;
--     end process p1;

--     p2 : process
--     begin
--         wait until rising_edge(clock);
--         done_p2 <= '0';
--         if reset_n /= '0' and done_p1 = '1' then
--             clocks_per_exposure_p2 <= CLOCKS_PER_SEC * exposure_time_p0 / 1000;
--             --clocks_per_frame_p2 <= clocks_per_frame_p1;
--             done_p2 <= '1';
--         end if;
--     end process p2;

--     p3 : process
--     begin
--         wait until rising_edge(clock);
--         done_p3 <= '0';
--         if reset_n /= '0' and done_p2 = '1' then
--             frame_request_offset_p3 <= clocks_per_exposure_p2 - EXTRA_EXPOSURE_CLOCKS;
--             --clocks_per_frame_p3 <= clocks_per_frame_p2;
--             done_p3 <= '1';
--         end if;
--     end process p3;

--     p4 : process
--     begin
--         wait until rising_edge(clock);
--         done <= '0';
--         if reset_n /= '0' and done_p3 = '1' then
            
--             offset <= frame_request_offset_p3;
--             done <= '1';

--             if frame_request_offset_p3 <= 0 then
--                 report "Can't compute frame_request_offset: requested exposure is too low" severity failure;
--                 offset <= 1;
--             end if;
            
--             if frame_request_offset_p3 + FOT_CLOCKS > clocks_per_frame_p1 then
--                 report "Can't compute frame_request_offset: requested exposure is too high" severity failure;
--                 offset <= clocks_per_frame_p1 - FOT_CLOCKS;
--             end if;

--         end if;
--     end process p4;

-- end architecture rtl;