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
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

use work.vnir_types.all;
use work.lvds_decoder_pkg.all;


entity lvds_decoder_out is
port (
    clock               : in std_logic;
    reset_n             : in std_logic;
    data_in_available   : in std_logic;
    from_fifo           : in fifo_data_t;
    align_done          : out std_logic;
    data_out_available  : out std_logic;
    parallel_out        : out vnir_parallel_lvds_t
);
end entity lvds_decoder_out;


architecture rtl of lvds_decoder_out is
    signal aligned_in : std_logic;
    signal control_in : vnir_pixel_t;
    signal data_in : vnir_pixel_vector_t(vnir_lvds_n_channels-1 downto 0);

    pure function is_aligned(fifo_data : fifo_data_t) return boolean is
    begin
        return or_reduce(get(fifo_data, 0)) = '1';
    end function is_aligned;
begin
    
    fsm : process
        type state_t is (RESET, ALIGNED, NONALIGNED);
        variable state : state_t;
    begin
        wait until rising_edge(clock);
        align_done <= '0';
        data_out_available <= '0';

        if reset_n = '0' then
            state := RESET;
        end if;

        case state is
        when RESET =>
            state := NONALIGNED;
        when NONALIGNED =>
            if is_aligned(from_fifo) then
                state := ALIGNED;
                align_done <= '1';
            end if;
        when ALIGNED =>
            if not is_aligned(from_fifo) then
                state := NONALIGNED;
            end if;
        end case;

        if state = ALIGNED then
            if data_in_available = '1' then
                data_out_available <= '1';
                parallel_out.control <= to_vnir_control(get(from_fifo, 1));
                for channel in 2 to n_fifo_channels-1 loop
                    parallel_out.data(channel-2) <= unsigned(get(from_fifo, channel));
                end loop;
            end if;
        end if;
    end process fsm;

end architecture rtl;