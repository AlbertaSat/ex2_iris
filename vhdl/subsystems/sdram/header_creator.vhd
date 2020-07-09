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
        reset_n         : in std_logic;

        --Timestamp for image dating
        timestamp       : in timestamp_t;

        --Header rows
        swir_img_header : out std_logic_vector (159 downto 0);
        vnir_img_header : out std_logic_vector (159 downto 0);

        -- Number of rows being created by the imagers
        vnir_rows       : in integer;
        swir_rows       : in integer;

        --Flag indicating the headers have been sent
        headers_sent    : out std_logic;
        sending_img     : in std_logic;
    );
end entity header_creator;

architecture rtl of header_creator is
    -- A function to turn a header record into a std_logic_vector for output
    function sdram_header_to_vec(header : sdram_header_t) return std_logic_vector (159 downto 0) is
    begin
        return (159 downto 96 => std_logic_vector(header.timestamp),
                95 downto 88 => header.user_defined,
                87 downto 72 => std_logic_vector(unsigned(header.x_size, 16)),
                71 downto 56 => std_logic_vector(unsigned(header.y_size, 16)),
                55 downto 40 => std_logic_vector(unsigned(header.z_size, 16)),
                39           => header.sample_type;
                38 downto 37 => header.reserved_1;
                36 downto 33 => std_logic_vector(header.dyna_range);
                32           => header.sample_encode;
                31 downto 16 => header.interleave_depth;
                15 downto 14 => header.reserved_2;
                13 downto 11 => std_logic_vector(header.output_word);
                10           => header.entropy_coder;
                9 downto 0   => header.reserved_3);
    end function sdram_header_to_vec;
    
begin
    main_process : process (clock) is
        --Defining constants for the different headers
        variable swir_header : sdram_header_t;
        variable vnir_header : sdram_header_t;

        --Flag to represet the previous header has been sent and a new one is not needed
        variable new_header_needed : std_logic := 1;
    begin

        if rising_edge(clock) then
            if (reset_n = '0') then
                --Assigning all values to 0
                swir_header.user_defined, vnir_header.user_defined := (others => '0');
                swir_header.x_size, vnir_header.x_size := 0;
                swir_header.y_size, vnir_header.y_size := 0;
                swir_header.z_size, vnir_header.z_size := 0; 
                swir_header.sample_type, vnir_header.sample_type := '0';
                swir_header.reserved_1, vnir_header.reserved_1 := "00";
                swir_header.dyna_ragne, vnir_header.dyna_range := 0;
                swir_header.sample_encode, vnir_header.sample_encode := '0';
                swir_header.interleave_depth, vnir_header.interleave_depth := (others => '0');
                swir_header.reserved_2, vnir_header.reserved_2 := "00";
                swir_header.output_word, vnir_header.output_word := 0;
                swir_header.entropy_coder, vnir_header.entropy_coder := '0';
                swir_header.reserved_3, vnir_header.reserved_3 := (others => '0');
               
            elsif (new_header_needed == '1') then
                if (vnir_header.user_defined(0) == '0' or vnir_header.user_defined(0) == 'U') then
                    --Assigning shared values to both headers
                    swir_header.user_defined, vnir_header.user_defined := (0 => 1, others => '0');
                    swir_header.sample_encode, vnir_header.sample_encode := '1';
                    swir_header.interleave_depth, vnir_header.interleave_depth := (others => '0');
                    swir_header.reserved_2, vnir_header.reserved_2 := "00";
                    swir_header.output_word, vnir_header.output_word := 1;
                    swir_header.entropy_coder, vnir_header.entropy_coder := '0';
                    swir_header.reserved_3, vnir_header.reserved_3 := (others => '0');

                    --Assigning values for differences between swir & vnir
                    swir_header.timestamp := to_unsigned(0, swir_header.timestamp'length)
                    swir_header.x_size := 512;
                    swir_header.y_size := 0;
                    swir_header.z_size := 1;
                    swir_header.dyna_range := 16;

                    vnir_header.timestamp := to_unsigned(0, vnir_header.timestamp'length)
                    vnir_header.x_size := 2048;
                    vnir_header.y_size := 0;
                    vnir_header.z_size := 3;
                    vnir_header.dyna_range := 10;

                elsif (to_integer(timestamp) /= 0 and swir_rows /= 0 and vnir_rows /= 0 and headers_sent == '0') then
                    swir_header.timestamp, vnir_header.timestamp := timestamp;
                    swir_header.y_size := swir_rows;
                    vnir_header.y_size := vnir_rows;

                    --Converting the records to std_logic_vectors and assiging the output signals
                    vnir_img_header <= sdram_header_to_vec(vnir_header);
                    swir_img_header <= sdram_header_to_vec(swir_header);
                    
                    headers_sent <= '1';
                
                -- Sneaky way of ensuring that the header isn't overwritten while waiting for the command
                -- creator to send back the sending_img signal
                elsif (sending_img == '1') then
                    new_header_needed == '0';
                    vnir_img_header <= (others => '0');
                    swir_img_header <= (others => '0');
                end if;

            else
                if sending_img == '0' then
                    new_header_needed := '1';
                    headers_sent <= '0';
                    swir_header.user_defined, vnir_header.user_defined := (others => '0');
                end if;
            end if;
        end if;
    end process;
end architecture;