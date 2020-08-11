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

entity command_creator is
    port(
        --Control Signals
        clock               : in std_logic;
        reset_n             : in std_logic;

        --Header data
        vnir_img_header     : in sdram_header_t;
        swir_img_header     : in sdram_header_t;

        --Rows
        row_data            : in vnir_row_t;

        --Addy
        address             : in sdram_address_block_t;

        -- Flags for MPU interaction
        sdram_busy          : in std_logic;
        mup_memory_change   : in sdram_address_block_t;

        --Avalon bridge for reading and writing to stuff
        read_out            : out avalonmm_read_from_master_t;
        write_in            : in avalonmm_write_to_master_t;
        write_out           : out avalonmm_write_from_master_t
    );
end entity command_creator;

architecture rtl of command_creator is
    component DMA_write is
        generic (
            DATAWIDTH 				: natural := 32;
            MAXBURSTCOUNT 			: natural := 4;
            BURSTCOUNTWIDTH 		: natural := 3;
            BYTEENABLEWIDTH 		: natural := 4;
            ADDRESSWIDTH			: natural := 32;
            FIFODEPTH				: natural := 32;
            FIFODEPTH_LOG2 			: natural := 5;
            FIFOUSEMEMORY 			: string := "ON"
	    );
        port (
            clk 					: in std_logic;
            reset 					: in std_logic;
            
            -- control inputs and outputs
            control_fixed_location 	: in std_logic;
            control_write_base 		: in std_logic_vector(ADDRESSWIDTH-1 downto 0);
            control_write_length 	: in std_logic_vector(ADDRESSWIDTH-1 downto 0);
            control_go 				: in std_logic;
            control_done			: out std_logic;
            
            -- user logic inputs and outputs
            user_write_buffer		: in std_logic;
            user_buffer_data		: in std_logic_vector(DATAWIDTH-1 downto 0);
            user_buffer_full		: out std_logic;
            
            -- master inputs and outputs
            master_address 			: out std_logic_vector(ADDRESSWIDTH-1 downto 0);
            master_write 			: out std_logic;
            master_byteenable 		: out std_logic_vector(BYTEENABLEWIDTH-1 downto 0);
            master_writedata 		: out std_logic_vector(DATAWIDTH-1 downto 0);
            master_burstcount 		: out std_logic_vector(BURSTCOUNTWIDTH-1 downto 0);
            master_waitrequest 		: in std_logic
        );
    end component;
begin
end architecture;