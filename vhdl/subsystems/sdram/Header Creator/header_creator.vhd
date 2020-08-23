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
use work.avalonmm;
use work.vnir;
use work.swir_types.all;
use work.sdram;
use work.fpga_types.all;

entity header_creator is 
    port (
        --Control Signals
        clock           : in std_logic;
        reset_n         : in std_logic;

        --Timestamp for image dating
        timestamp       : in timestamp_t;

        --Header rows
        swir_img_header : out sdram.header_t;
        vnir_img_header : out sdram.header_t;

        -- Number of rows being created by the imagers
        vnir_rows       : in integer;
        swir_rows       : in integer;

        --Flag indicating the imager is working
        sending_img     : in std_logic
    );
end entity header_creator;

architecture rtl of header_creator is
    --Counter variable for the user defined bits indicating image number
    signal counter          : unsigned (7 downto 0) := "00000000";
    signal counter_inc_flag : std_logic;

    component edge_detector is 
        generic(fall_edge : boolean);
        port(
            clk, reset_n, ip : in std_logic;
            edge_flag : out std_logic);
    end component edge_detector;
begin
    --Values for the headers
    swir_img_header <= std_logic_vector(timestamp) &                    --Timestamp (64 bits)
                       std_logic_vector(counter) &                      --User Defined [img number defined by counter] (8 bits)
                       "0000001000000000" &                             --X Size [512 px/row for swir] (16 bits)
                       std_logic_vector(to_unsigned(swir_rows, 16)) &   --Y Size (16 bits)
                       "0000000000000001" &                             --Z Size [1 for swir] (16 bits)
                       '0' &                                            --Sample Type (1 bit)
                       "11" &                                           --Reserved (2 bits)
                       "0000" &                                         --Dynamic Range [16 bit/px for swir] (4 bits)
                       '1' &                                            --BSQ format (1 bit)
                       "0000000000000000" &                             --Interleave Depth (16 bits)
                       "00" &                                           --Reserved
                       "001" &                                          --Output word length (3 bits)
                       '0' &                                            --Entropy Encoding
                       "0000000000";                                    --Reserved (10 bits)
    
    
    vnir_img_header <= std_logic_vector(timestamp) &                    --Timestamp (64 bits)
                       std_logic_vector(counter) &                      --User Defined [img number defined by counter] (8 bits)
                       "0000100000000000" &                             --X Size [2048 px/row for vnir] (16 bits)
                       std_logic_vector(to_unsigned(vnir_rows, 16)) &   --Y Size (16 bits)
                       "0000000000000011" &                             --Z Size [3 for vnir] (16 bits)
                       '0' &                                            --Sample Type (1 bit)
                       "11" &                                           --Reserved (2 bits)
                       "1010" &                                         --Dynamic Range [10 bit/px for vnir] (4 bits)
                       '1' &                                            --BSQ format (1 bit)
                       "0000000000000000" &                             --Interleave Depth (16 bits)
                       "00" &                                           --Reserved
                       "001" &                                          --Output word length (3 bits)
                       '0' &                                            --Entropy Encoding
                       "0000000000";                                    --Reserved (10 bits)
    
    --Incrementing the counter when a falling edge of the sending image flag is received
    fall_edge_detect : edge_detector generic map(true) port map(clock, reset_n, sending_img, counter_inc_flag);
    
    counter_process : process (clock) is
    begin
        if rising_edge(clock) then
            if (counter_inc_flag = '1') then
                counter <= counter + 1;
            end if;
        end if;
    end process;
end architecture;