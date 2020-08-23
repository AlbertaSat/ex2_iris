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

use work.avalonmm_types.all;
use work.vnir;
use work.img_buffer_pkg.all;
use work.swir_types.all;
use work.sdram;
use work.fpga_types.all;

entity imaging_buffer is
    port(
        --Control Signals
        clock           : in std_logic;
        reset_n         : in std_logic;

        --Rows of Data
        vnir_row        : in vnir.row_t;
        swir_pixel      : in swir_pixel_t;

        --Rows out
        vnir_row_out    : out vnir.row_t;
        swir_row_out    : out swir_row_t;
        row_request     : in std_logic;

        --Flag signals
        swir_row_ready  : in std_logic;
        vnir_row_ready  : in vnir.row_type_t
    );
end entity imaging_buffer;

architecture rtl of imaging_buffer is
    --SWIR words are 64 bits (4 pixel per word)
    component SWIR_Row_FIFO port (
		aclr		: in std_logic;
		clock		: in std_logic;
		data		: in std_logic_vector (63 downto 0);
		rdreq		: in std_logic;
		wrreq		: in std_logic;
		empty		: out std_logic;
		full		: out std_logic;
		q		: out std_logic_vector (63 downto 0);
		usedw		: out std_logic_vector (6 downto 0));
    end component VNIR_Row_FIFO;
    
    --VNIR words are 160 bits (16 pixels per word)
    component VNIR_Row_FIFO port (
        aclr		: in std_logic;
        clock		: in std_logic;
        data		: in std_logic_vector (159 downto 0);
        rdreq		: in std_logic;
        wrreq		: in std_logic;
        empty		: out std_logic;
        full		: out std_logic;
        q		    : out std_logic_vector (159 downto 0);
        usedw		: out std_logic_vector (6 downto 0));
    end component VNIR_Row_FIFO;

    signal fifo_clear : std_logic;

    --signals for the first stage of the vnir pipeline
    signal vnir_row_ready_i : vnir.row_type_t;
    signal vnir_row_fragments : vnir_row_fragments_a;

    --signals for the second stage of the vnir pipeline
    signal row_type_buffer : row_type_buffer_a;
    signal vnir_link : vnir_link_a;
    signal vnir_frag_counter : integer;
begin
    --Generating a chain of FIFOs for both the vnir & swir rows, 
    --each FIFO capable of holding 10 rows of each type, with 128
    --words in each
    for i in 0 to NUM_VNIR_ROW_FIFO-1 generate
        VNIR_FIFO : VNIR_Row_FIFO port map (
            aclr => fifo_clear,
            clock => clock,
            data => vnir_link(i),
            rdreq => ,
            wrreq => ,
            empty => ,
            full => ,
            q => vnir_link(i+1),
            usedw =>
        );
    end generate;

    for i in 0 to NUM_SWIR_ROW_FIFO-1 generate
        SWIR_FIFO : SWIR_Row_FIFO port map (
            aclr => fifo_clear,
            clock => clock,
            data => vnir_link(i),
            rdreq => ,
            wrreq => ,
            empty => ,
            full => ,
            q => vnir_link(i+1),
            usedw =>
        );
    end generate;

    --This process details the vnir dataflow
    vnir_pipeline : process (reset_n, clock) is
    begin
        if (reset_n = '0') then
            vnir_row_ready_i <= no_row;
            vnir_row_fragments <= (others => (others => '0'));

            fifo_clear <= '1';
            counter <= 0;
            vnir_link(0) <= (others => '0');
        elsif rising_edge(clock) then
            --The first stage of the vnir pipeline, storing data taken from the vnir system
            vnir_row_ready_i <= vnir_row_ready;
            for i in 0 to 127 loop
                vnir_row_fragments(i) <= std_logic_vector(vnir_row(0  + i * 16)) &
                                         std_logic_vector(vnir_row(1  + i * 16)) &
                                         std_logic_vector(vnir_row(2  + i * 16)) &
                                         std_logic_vector(vnir_row(3  + i * 16)) &
                                         std_logic_vector(vnir_row(4  + i * 16)) &
                                         std_logic_vector(vnir_row(5  + i * 16)) &
                                         std_logic_vector(vnir_row(6  + i * 16)) &
                                         std_logic_vector(vnir_row(7  + i * 16)) &
                                         std_logic_vector(vnir_row(8  + i * 16)) &
                                         std_logic_vector(vnir_row(9  + i * 16)) &
                                         std_logic_vector(vnir_row(10 + i * 16)) &
                                         std_logic_vector(vnir_row(11 + i * 16)) &
                                         std_logic_vector(vnir_row(12 + i * 16)) &
                                         std_logic_vector(vnir_row(13 + i * 16)) &
                                         std_logic_vector(vnir_row(14 + i * 16)) &
                                         std_logic_vector(vnir_row(15 + i * 16));
            end loop;
            

            if (vnir_frag_counter < 127 and vnir_row_ready_i /= no_row) then
                vnir_link(0) <= vnir_row_fragments(vnir_frag_counter);
                counter <= counter + 1;
            else
                vnir_frag_counter <= 0;
                vnir_link(0) <= (others => '0');
            end if;
        end if;
    end process vnir_reg_store;

    --Stage 3 of vnir pipeline, in the fifo chain
    vnir_fifo_chain : process (reset_n, clock) is
        

            
end architecture;