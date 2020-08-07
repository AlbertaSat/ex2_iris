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

use work.vnir_common.all;
use work.lvds_decoder_pkg.all;


entity lvds_decoder_out is
port (
    clock               : in std_logic;
    reset_n             : in std_logic;
    data_in_available   : in std_logic;
    from_fifo           : in fifo_data_t;
    align_done          : out std_logic;
    fragment            : out fragment_t;
    fragment_control    : out control_t;
    fragment_available  : out std_logic
);
end entity lvds_decoder_out;


architecture rtl of lvds_decoder_out is
begin
    
    fsm : process
        type state_t is (RESET, ALIGNED, NONALIGNED);
        variable state : state_t;
    begin
        wait until rising_edge(clock);
        align_done <= '0';
        fragment_available <= '0';

        if reset_n = '0' then
            state := RESET;
        end if;

        case state is
        when RESET =>
            state := NONALIGNED;
        when NONALIGNED =>
            if from_fifo.is_aligned = '1' then
                state := ALIGNED;
                align_done <= '1';
            end if;
        when ALIGNED =>
            if from_fifo.is_aligned /= '1' then
                state := NONALIGNED;
            end if;
        end case;

        if state = ALIGNED then
            if data_in_available = '1' then
                fragment_available <= '1';
                fragment_control <= from_fifo.control;
                fragment <= from_fifo.fragment;
            end if;
        end if;
    end process fsm;

end architecture rtl;