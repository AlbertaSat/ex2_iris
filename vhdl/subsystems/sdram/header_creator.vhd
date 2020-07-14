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

        --Flag indicating the imager is still working
        sending_img     : in std_logic
    );
end entity header_creator;

architecture rtl of header_creator is
    --Creating the enumerator for the state machine
    type header_creator_state_t is (init, assign, sending);
    signal state : header_creator_state_t := init;

    -- A function to turn a header record into a std_logic_vector for output
    function header2vec(header : sdram_header_t) return std_logic_vector is
	    variable buffer_vec : std_logic_vector (159 downto 0);
    begin
        buffer_vec := std_logic_vector(header.timestamp) &
                      header.user_defined &
                      std_logic_vector(to_unsigned(header.x_size, 16)) &
                      std_logic_vector(to_unsigned(header.y_size, 16)) &
                      std_logic_vector(to_unsigned(header.z_size, 16)) &
                      header.sample_type &
                      header.reserved_1 &
                      std_logic_vector(to_unsigned(header.dyna_range, 4)) &
                      header.sample_encode &
                      header.interleave_depth &
                      header.reserved_2 &
                      std_logic_vector(to_unsigned(header.output_word, 3)) &
                      header.entropy_coder &
                      header.reserved_3;

	    return buffer_vec;
    end function header2vec;
begin
    main_process : process (clock) is
        --Creating an initial header with default values that fit both SWIR & VNIR Images
        --TODO: Maybe specialize the user defined part?
        constant init_header : sdram_header_t := (
            timestamp   => to_unsigned(0, timestamp'length),
            user_defined => (0 => '1', others => '0'),
            x_size              => 0,
            y_size              => 0,
            z_size              => 0,
            sample_type         => '0',
            reserved_1          => "00",
            dyna_range          => 0,
            sample_encode       => '1',
            interleave_depth    => (others => '0'),
            reserved_2          => "00",
            output_word         => 1,
            entropy_coder       => '0',
            reserved_3          => (others => '0')
        );

        --Assigning the headers to be the same as the initial header
        variable swir_header : sdram_header_t;
        variable vnir_header : sdram_header_t;
    begin

        if rising_edge(clock) then
            --Reset causes the header creator to reset back to initial values
            if (reset_n = '0') then
                state <= init;

                --Reseting the output headers
                swir_img_header <= (others => '0');
                vnir_img_header <= (others => '0');
               
            else
                case state is
                    when init =>
                        --Setting the variable headers to be the same as the init_header, then customizing
                        swir_header := init_header;
                        vnir_header := init_header;

                        swir_header.x_size      := 512;
                        swir_header.z_size      := 1;
                        swir_header.dyna_range  := 16;

                        vnir_header.x_size      := 2048;
                        vnir_header.z_size      := 3;
                        vnir_header.dyna_range  := 10;

                        --Setting to idle state
                        state <= assign;

                        --Setting the outputs to zero
                        swir_img_header <= (others => '0');
                        vnir_img_header <= (others => '0');

                    when assign =>
                        --Just waiting for the timestamp and the rows
                        if (to_integer(timestamp) /= 0 and swir_rows /= 0 and vnir_rows /= 0) then
                            --Next state is sending
                            state <= sending;

                            --Assigning the output rows to the correct ones 
                            swir_header.timestamp := timestamp;
                            vnir_header.timestamp := timestamp;

                            swir_header.y_size := swir_rows;
                            vnir_header.y_size := vnir_rows;

                            swir_img_header <= header2vec(swir_header);
                            vnir_img_header <= header2vec(vnir_header);
                        end if;

                    when sending =>
                        --This state waits for the image to stop writing before freeing the header creator
                        if sending_img = '0' then
                            state <= init;
                            swir_img_header <= (others => '0');
                            vnir_img_header <= (others => '0');
                        end if;
                end case;
            end if;
        end if;
    end process;
end architecture;