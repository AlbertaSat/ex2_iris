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

entity header_creator_tb is
end entity;

architecture sim of header_creator_tb is
    --Clock frequency is 20 MHz
    constant clock_frequency    : integer := 20000000;
    constant clock_period       : time := 1000 ms / clock_frequency;
    
    --Control inputs
    signal clock                : std_logic := '1';
    signal reset_n              : std_logic := '0';

    --Non-control inputs
    signal timestamp            : timestamp_t := to_unsigned(0, timestamp_t'length);
    signal vnir_rows            : integer := 0;
    signal swir_rows            : integer := 0;
    signal sending_img          : std_logic := '0';

    --Outputs
    signal swir_img_header      : std_logic_vector(159 downto 0);
    signal vnir_img_header      : std_logic_vector(159 downto 0);

    signal swir_header          : sdram_header_t;
    signal vnir_header          : sdram_header_t;

    function vec_to_header(vector_header : std_logic_vector) return sdram_header_t is
        variable buffer_header : sdram_header_t;
    begin
        buffer_header.timestamp         := unsigned(vector_header(159 downto 96));
        buffer_header.user_defined      := vector_header(95 downto 88);
        buffer_header.x_size            := to_integer(unsigned(vector_header(87 downto 72)));
        buffer_header.y_size            := to_integer(unsigned(vector_header(71 downto 56)));
        buffer_header.z_size            := to_integer(unsigned(vector_header(55 downto 40)));
        buffer_header.sample_type       := vector_header(39);
        buffer_header.reserved_1        := vector_header(38 downto 37);
        buffer_header.dyna_range        := to_integer(unsigned(vector_header(36 downto 33)));
        buffer_header.sample_encode     := vector_header(32);
        buffer_header.interleave_depth  := vector_header(31 downto 16);
        buffer_header.reserved_2        := vector_header(15 downto 14);
        buffer_header.output_word       := to_integer(unsigned(vector_header(13 downto 11)));
        buffer_header.entropy_coder     := vector_header(10);
        buffer_header.reserved_3        := vector_header(9 downto 0);

        return buffer_header;
    end function vec_to_header;
begin
    i_header_creator : entity work.header_creator(rtl)
    port map(
        clock           => clock,
        reset_n         => reset_n,
        timestamp       => timestamp,
        vnir_rows       => vnir_rows,
        swir_rows       => swir_rows,
        sending_img     => sending_img,
        swir_img_header => swir_img_header,
        vnir_img_header => vnir_img_header);
    
    clock <= not clock after clock_period / 2;

    --Testing stuff
    testing_process : process is
    begin
        --Waiting two clock cycles before taking it out of reset
        wait until rising_edge(clock);
        wait until rising_edge(clock);

        reset_n <= '1';
        
        wait until rising_edge(clock);

        timestamp <= to_unsigned(1594402392, 64);
        vnir_rows <= 23;
        swir_rows <= 12;

        wait until (swir_img_header(0) /= 'U');

        swir_header <= vec_to_header(swir_img_header);
        vnir_header <= vec_to_header(vnir_img_header);

        sending_img <= '1';

        wait until rising_edge(clock);
    end process testing_process;
end architecture;