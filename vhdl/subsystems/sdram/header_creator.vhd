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
        vnir_rows       : in natural;
        swir_rows       : in natural;

        vnir_rows_out   : out natural;
        swir_rows_out   : out natural;

        --Flag indicating the headers have been sent
        headers_sent    : out std_logic;
        sending_img     : in std_logic;
    );
end entity header_creator;

architecture rtl of header_creator is
    --Flag to determine whether or not the rest of the header can be created
    signal timestamp_rxd      : std_logic;

    --Buffer headers to be created before being sent out
    signal swir_buffer_header   : sdram_header;
    signal vnir_buffer_header   : sdram_header;
begin
    main_process : process (clock, reset) is
    begin
        if (reset = '1') then
            --TODO: Add reset procedure here

        elsif rising_edge(clock) then
            if (to_integer(timestamp) /= 0 and sending_img == '0') then
                --updating both header buffers with the timestamp at the beginning
                swir_buffer_header <= swir_buffer_header(159 downto 64) & std_logic_vector(timestamp);
                vnir_buffer_header <= vnir_buffer_header(150 downto 64) & std_logic_vector(timestamp);

                --Updating the timestamp received flag
                timestamp_rxd <= '1';
            end if;

            --Checking SWIR header first because why not
            if (swir_rows /= 0 and timestamp_rxd == true) then
                
            end if;

            if (vnir_rows /= 0 and timestamp_rxd == true) then
                --TODO: Also define this ish (I'm getting kinda lazy jeez)
            end if;
        end if;
    end process;
end architecture;