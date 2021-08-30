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

--TODO: 
-- 1) add state to write header data
-- 2) register address 
--       both of these are the same thing. need to know when fpga subsystem is first giving command and give write commands appropriately

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vnir;
use work.sdram;

use work.img_buffer_pkg.all;
use work.custom_master_pkg.all;
use work.swir_types.all;
use work.fpga.all;
use work.sdram."=";

entity command_creator is
    port(
        --Control Signals
        clock               : in std_logic;
        reset_n             : in std_logic;

        --Header data
        vnir_img_header     : in sdram.header_t;
        swir_img_header     : in sdram.header_t;

        --Rows
        row_data            : in row_fragment_t;
        row_type            : in sdram.row_type_t;
        buffer_transmitting : in std_logic;
        address             : in sdram.address_t;
        
        --Output Flag to Imaging Buffer
        next_row_req        : out std_logic;

        --Output Flag to MPU
        sdram_busy          : out std_logic;

        --Commands to custom master
        master_cmd_in       : in from_master_t;
        master_cmd_out      : out to_master_t
    );
end entity command_creator;

architecture rtl of command_creator is
   
    -- -- signals
    -- signal control_fixed_location   : std_logic;
    -- signal control_write_length     : std_logic_vector(sdram.ADDRESS_LENGTH-1 downto 0);
    -- signal control_write_base       : std_logic_vector(sdram.ADDRESS_LENGTH-1 downto 0);
    -- signal control_go               : std_logic;
    -- signal control_done             : std_logic;
    -- signal user_write_buffer        : std_logic;
    -- signal user_buffer_data         : std_logic_vector(FIFO_WORD_LENGTH-1 downto 0);
    -- signal user_buffer_full         : std_logic;

    -- registers
    signal address_reg              : sdram.address_t;
    signal row_type_reg             : sdram.row_type_t;

	type state_type is (s0_reset, s1_empty, s2_write_cmd, s3_writing);
        signal state   : state_type;   -- Register to hold the current state

        -- Attribute "safe" implements a safe state machine. 
        -- It can recover from an illegal state (by returning to the reset state).
        attribute syn_encoding : string;
        attribute syn_encoding of state_type : type is "safe";

begin

    -- -- work with internal signals
    -- master_cmd_out.control_fixed_location <= control_fixed_location;
    -- master_cmd_out.control_write_base     <= control_write_base;
    -- master_cmd_out.control_write_length   <= control_write_length;
    -- master_cmd_out.control_go             <= control_go;
    -- master_cmd_out.user_write_buffer      <= user_write_buffer;
    -- master_cmd_out.user_buffer_data       <= user_buffer_data;
    
    -- control_done                          <= master_cmd_in.control_done;
    -- user_buffer_full                      <= master_cmd_in.user_buffer_full;

    -- state machine transfers
    process (reset_n, clock) is
    begin
        if (reset_n = '0') then
            row_type_reg <= sdram.ROW_NONE;
            state <= s0_reset;
        elsif rising_edge(clock) then
			case state is
				when s0_reset =>
					if reset_n = '1' then
						state <= s1_empty;
					else
						state <= s0_reset;
					end if;
				when s1_empty =>  
					if buffer_transmitting = '1' then
                        row_type_reg <= row_type;    -- register the row type that's coming
						state <= s2_write_cmd;       
					else
						state <= s1_empty;
					end if;
				when s2_write_cmd =>
                    state <= s3_writing;
                when s3_writing =>
                    if master_cmd_in.control_done = '1' then 
                        state <= s1_empty;
                    else
                        state <= s3_writing;
                    end if;
                when others =>
                    state <= s0_reset;
			end case;
        end if;
    end process;
    
    -- output signals 
    next_row_req            <= '1' when state = s1_empty else '0';
    sdram_busy              <= '1' when ((state = s2_write_cmd) or (state = s3_writing)) else '0';
        
    -- command to write master
    master_cmd_out.control_fixed_location  <= '0';
    master_cmd_out.control_go              <= '1' when state = s2_write_cmd else '0';
    
    -- data to write master
    master_cmd_out.user_write_buffer       <= '1' when state = s3_writing else '0';
    master_cmd_out.user_buffer_data        <= row_data when state = s3_writing else (others => '0');

    -- setting address and write length for write master 
    process (state) is
    begin 
        if (state = s2_write_cmd) then
            -- base address
            master_cmd_out.control_write_base      <= std_logic_vector(address_reg); 

            -- write length
            if row_type_reg = sdram.ROW_SWIR then 
                master_cmd_out.control_write_length    <= std_logic_vector(to_unsigned(SWIR_ROW_BYTES, sdram.ADDRESS_LENGTH));
            elsif (row_type_reg = sdram.ROW_RED or row_type_reg = sdram.ROW_BLUE or row_type_reg = sdram.ROW_NIR) then 
                master_cmd_out.control_write_length    <= std_logic_vector(to_unsigned(VNIR_ROW_BYTES, sdram.ADDRESS_LENGTH));
            else 
                master_cmd_out.control_write_length    <= (others => '0');
            end if;
        else 
            master_cmd_out.control_write_base      <= (others => '0');
            master_cmd_out.control_write_length    <= (others => '0');
        end if;
    end process;
    
    address_reg <= address; -- TODO: FIX

end architecture;