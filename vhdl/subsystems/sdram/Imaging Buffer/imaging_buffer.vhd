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

use work.avalonmm;
use work.img_buffer_pkg.all;
use work.swir_types.all;
use work.sdram;
use work.fpga_types.all;

use work.vnir;
use work.vnir."/=";

entity imaging_buffer is
    port(
        --Control Signals
        clock               : in std_logic;
        reset_n             : in std_logic;

        --Rows of Data
        vnir_row            : in vnir.row_t;
        swir_pixel          : in swir_pixel_t;

        --Rows out
        fragment_out        : out row_fragment_t;
        fragment_type       : out sdram.row_type_t;
        row_request         : in std_logic;

        --Flag signals
        swir_pixel_ready    : in std_logic;
        vnir_row_ready      : in vnir.row_type_t
    );
end entity imaging_buffer;

architecture rtl of imaging_buffer is
    --SWIR words are 64 bits (4 pixel per word)
    component SWIR_Row_FIFO port (
		aclr		: in std_logic;
		clock		: in std_logic;
		data		: in std_logic_vector (127 downto 0);
		rdreq		: in std_logic;
		wrreq		: in std_logic;
		empty		: out std_logic;
		full		: out std_logic;
		q		    : out std_logic_vector (127 downto 0));
    end component SWIR_Row_FIFO;
    
    --VNIR words are 160 bits (16 pixels per word)
    component VNIR_Row_FIFO port (
        aclr		: in std_logic;
        clock		: in std_logic;
        data		: in std_logic_vector (127 downto 0);
        rdreq		: in std_logic;
        wrreq		: in std_logic;
		almost_full : out std_logic;
        empty		: out std_logic;
        full		: out std_logic;
        q		    : out std_logic_vector (127 downto 0));
    end component VNIR_Row_FIFO;

    signal fifo_clear : std_logic;

    --signals for the first stage of the vnir pipeline
    signal vnir_row_ready_i : vnir.row_type_t;
    signal vnir_row_fragments : vnir_row_fragment_a;

    --Signals for the first stage of the swir pipeline
    signal swir_bit_counter : integer;
    signal swir_fragment : row_fragment_t;

    --signals for the second stage of the vnir pipeline
    signal row_type_buffer : row_type_buffer_a;
    signal vnir_frag_counter : integer;
    signal vnir_link : vnir_link_a;

    --Signal for the second stage of the swir pipeline
    signal swir_fragment_ready : std_logic;
    signal swir_link : swir_link_a;

    --Signals for the third stage of the swir pipeline
    signal swir_link_transfer   : std_logic_vector(0 to NUM_SWIR_ROW_FIFO);
    signal swir_fifo_empty      : std_logic_vector(0 to NUM_SWIR_ROW_FIFO-1);
    signal swir_fifo_full       : std_logic_vector(0 to NUM_SWIR_ROW_FIFO-1);

    --Signals for the third stage of the vnir pipeline
    --This one's kinda cheating, im treating a vector like an array of booleans lol
    signal vnir_link_transfer   : std_logic_vector(0 to NUM_VNIR_ROW_FIFO);
    signal vnir_fifo_empty      : std_logic_vector(0 to NUM_VNIR_ROW_FIFO-1);
    signal vnir_fifo_full       : std_logic_vector(0 to NUM_VNIR_ROW_FIFO-1);
begin
    --Generating a chain of FIFOs for both the vnir & swir rows, 
    --each FIFO capable of holding 10 rows of each type, words of 128 bits each
    --NOTE: The ip doesn't allow for choosing a FIFO with a depth of 160 words, so
    --the almost full signal is used in the full signal's place
    VNIR_FIFO_GEN : for i in 0 to NUM_VNIR_ROW_FIFO-1 generate
        VNIR_FIFO : VNIR_Row_FIFO port map (
            aclr => fifo_clear,
            clock => clock,
            data => vnir_link(i),
            rdreq => vnir_link_transfer(i+1),
            wrreq => vnir_link_transfer(i),
            almost_full => vnir_fifo_full(i),
            empty => vnir_fifo_empty(i),
            full => open,
            q => vnir_link(i+1)
        );
    end generate VNIR_FIFO_GEN;

    SWIR_FIFO_GEN : for i in 0 to NUM_SWIR_ROW_FIFO-1 generate
        SWIR_FIFO : SWIR_Row_FIFO port map (
            aclr => fifo_clear,
            clock => clock,
            data => swir_link(i),
            rdreq => swir_link_transfer(i+1),
            wrreq => swir_link_transfer(i),
            empty => swir_fifo_empty(i),
            full => swir_fifo_full(i),
            q => swir_link(i+1)
        );
    end generate SWIR_FIFO_GEN;

    --This process details the vnir dataflow
    vnir_pipeline : process (reset_n, clock) is
        variable vnir_link_transfer_prev : std_logic_vector(0 to NUM_VNIR_ROW_FIFO);

        --Variables used to help calculate the pixels that need to be split up to store the data in the FIFO
        variable pixel_num      : natural := 0;
        variable pixel_bit      : natural := 0;
    begin
        if (reset_n = '0') then
            vnir_row_ready_i <= vnir.ROW_NONE;
            vnir_row_fragments <= (others => (others => '0'));

            fifo_clear <= '1';
            vnir_frag_counter <= 0;
            vnir_link(0) <= (others => '0');
        elsif rising_edge(clock) then
            --The first stage of the vnir pipeline, storing data taken from the vnir system
            if (vnir_row_ready /= vnir.ROW_NONE) then
                vnir_row_ready_i <= vnir_row_ready;
                for frag_array_index in 0 to VNIR_FIFO_DEPTH-1 loop
                    for frag_array_bit in 0 to FIFO_WORD_LENGTH-1 loop
                        vnir_row_fragments(frag_array_index)(frag_array_bit) <= vnir_row(pixel_num)(pixel_bit);

                        --Conditional logic for incrementing pixel and but info
                        if (pixel_bit = vnir.PIXEL_BITS-1) then
                            pixel_bit := 0;
                            pixel_num := pixel_num + 1;
                        else
                            pixel_bit := pixel_bit + 1;
                        end if;
                    end loop;
                
                    --Reseting the variables
                    if (frag_array_index = VNIR_FIFO_DEPTH-1) then
                        pixel_bit := 0;
                        pixel_num := 0;
                    end if;
                end loop;
            end if;
            
            --Second stage of the VNIR pipeline, storing data into the fifo chain
            if (vnir_frag_counter < VNIR_FIFO_DEPTH and vnir_row_ready_i /= vnir.ROW_NONE) then
                vnir_link(0) <= vnir_row_fragments(vnir_frag_counter);
                vnir_link_transfer(0) <= '1';
                vnir_frag_counter <= vnir_frag_counter + 1;

                --If it's the last word getting stored, adding the type to the type buffer
                if (vnir_frag_counter = VNIR_FIFO_DEPTH-1) then
                    row_type_buffer(0) <= vnir_row_ready_i;
                    vnir_row_ready_i <= vnir.ROW_NONE;
                end if;

            else
                vnir_frag_counter <= 0;
                vnir_link(0) <= (others => '0');
                vnir_link_transfer(0) <= '0';
            end if;

            --Third stage of the VNIR pipeline, transfering data through the FIFO chain
            for i in 1 to NUM_VNIR_ROW_FIFO-1 loop
                --This writes data through the chain
                if (vnir_fifo_empty(i+1) = '1' and vnir_fifo_full(i) = '1') then
                    vnir_link_transfer(i) <= '1';
                elsif (vnir_fifo_full(i+1) = '1' and vnir_fifo_empty(i) = '1') then
                    vnir_link_transfer(i) <= '0';
                end if;

                --This writes the type through the chain
                if ((vnir_link_transfer(i) /= vnir_link_transfer_prev(i)) and (vnir_link_transfer(i) = '0')) then
                    row_type_buffer(i + 1) <= row_type_buffer(i);
                end if;

                vnir_link_transfer_prev(i) := vnir_link_transfer(i);
            end loop;

            --Fourth stage of the VNIR pipeline, getting the data out


        end if;
    end process vnir_pipeline;

    swir_pipeline : process (reset_n, clock) is
    begin
        if (reset_n = '0') then
            swir_bit_counter <= 0;
            swir_fragment <= (others => '0');

            swir_fragment_ready <= '0';

        elsif rising_edge(clock) then
            --The first stage of the swir_pipeline, accumulating pixels to fill a word
            if (swir_pixel_ready = '1') then
                swir_fragment(swir_bit_counter + SWIR_PIXEL_BITS downto swir_bit_counter) <= std_logic_vector(swir_pixel);

                if (swir_bit_counter = FIFO_WORD_LENGTH-1) then
                    swir_fragment_ready <= '1';
                    swir_bit_counter <= 0;
                else
                    swir_bit_counter <= swir_bit_counter + SWIR_PIXEL_BITS;
                end if;
            end if;

            --The second stage of the swir pipeline, putting the fragment into the fifo chain
            if (swir_fragment_ready = '1') then
                swir_link_transfer(0) <= '1';
                swir_link(0) <= swir_fragment;
            else
                swir_link_transfer(0) <= '0';
                swir_link(0) <= (others => '0');
            end if;

            --Third stage of the SWIR pipeline, transfering data through the FIFO chain
            for i in 1 to NUM_SWIR_ROW_FIFO-1 loop
                --This writes data through the chain
                if (swir_fifo_empty(i+1) = '1' and swir_fifo_full(i) = '1') then
                    swir_link_transfer(i) <= '1';
                elsif (swir_fifo_full(i+1) = '1' and swir_fifo_empty(i) = '1') then
                    swir_link_transfer(i) <= '0';
                end if;
            end loop;

            --
            
        end if;
    end process swir_pipeline;
    
end architecture;