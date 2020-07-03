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

use work.spi_types.all;
use work.avalonmm_types.all;
use work.vnir_types.all;
use work.swir_types.all;
use work.sdram_types.all;
use work.fpga_types.all;

entity header_creator is 
    port (
        --Control Signals
        clock           : in std_logic;
        reset           : in std_logic;

        --Timestamp for image dating
        timestamp       : in timestamp_t;

        --Header rows
        swir_img_header : out sdram_header;
        vnir_img_header : out sdram_header;

        -- Number of rows being created by the imagers
        vnir_rows       : inout integer range 0 to integer'high;
        swir_rows       : inout integer range 0 to integer'high;

        --Flag indicating the headers have been sent
        headers_sent    : out std_logic;
    );
end entity header_creator;

architecture rtl of header_creator is

begin
    main_process : process (clock, reset) is
        if (reset = '1') then
            --TODO: Add reset procedure here
        end if;

        if rising_edge(clock) then
            --Checking SWIR header first because why not
            if (swir_rows /= 0) then
                --TODO: Define this ish
            elsif (vnir_rows /= 0) then
                --TODO: Also define this ish (I'm getting kinda lazy jeez)
            end if;
        end if;
    end process;
end architecture;