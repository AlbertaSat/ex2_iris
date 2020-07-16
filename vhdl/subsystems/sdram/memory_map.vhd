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

entity memory_map is
    port (
        --Control signals
        clock               : in std_logic;
        reset_n             : in std_logic;

        --SDRAM config signals to and from the FPGA
        config              : in sdram_config_to_sdram_t;
        memory_state        : out sdram_partitions_t;

        start_config        : in std_logic;
        config_done         : out std_logic;

        --Image Config signals
        number_swir_rows    : in natural;
        number_vnir_rows    : in natural;

        --Ouput image row address config
        next_row_type       : in sdram_next_row_fed;
        row_address         : out sdram_address_block_t;

        --Read data to be read from sdram due to mpu interaction
        sdram_error         : out sdram_error_t;
        read_data           : in avalonmm_read_to_master_t;
    );
end entity memory_map;

architecture rtl of memory_map is
    --FSM signals
    type t_state is (init, sys_config, idle, img_config, row_assign, mpu_check);
    signal state : t_state := init;

    --Variables detailing the amount of rows left in the imaging proces
    signal red_rows_left    : natural   := 0;
    signal blue_rows_left   : natural   := 0;
    signal nir_rows_left    : natural   := 0;
    signal swir_rows_left   : natural   := 0;

    signal vnir_size        : natural   := 0;
    signal swir_size        : natural   := 0;

    --Start addresses for the images
    signal vnir_start_address   : natural := 0;
    signal swir_start_address   : natural := 0;

    --Flag for whether or not the memory location for the swir header has been sent
    signal swir_header_sent : std_logic := '0';

    --Checks if the image will overflow the position, returns 1 if it does
    function check_overflow(partition : partition_t, bit_size : natural) return std_logic is
    begin
        if (partition.filled_bounds + bit_size / 16 > partition.bounds) then
            return '1';
        else
            return '0';
        end if;
    end function check_overflow;
    
    --Checks if the image won't fit in the memory because it is too full, returns 1 if it does
    function check_full(partition : partition_t, bit_size : natural, start_address : natural) return std_logic is
    begin
        if (start_address <= partition.fill_base and start_address + bit_size / 16 >= partition.fill_base) then
            return '1';
        else
            return '0';
        end if;
    end function check_full;

begin

    --The main process for everything
    main_process : process (clock, reset) is
        --A zero mem array for easy init
        constant zero_mem : partition_t := (
            base        => 0,
            bounds      => 0,
            fill_base   => 0,
            fill_bounds => 0
        );
    begin
        if rising_edge(clock) then
            if (reset_n = '0') then
                --If reset is asserted, initializing and writing everything to 0
                state <= init;

            else
                case state is
                    when init =>
                        sdram_error <= NO_ERROR;
                        row_address <= (0, 0);
                        config_done <= '0';
                        memory_state <= (
                            vnir        => zero_mem,
                            swir        => zero_mem,
                            vnir_temp   => zero_mem,
                            swir_temp   => zero_mem
                        );

                        --Init just waits for start_config signal to start the configuration of the SDRAM
                        if start_config = '1' then
                            state <= sys_config;
                        end if;

                    when sys_config =>
                        --Creating the minimum and maximum locations for vnir and swir images
                        --TODO: Create a mapping process with the sizes of each taken into account
                        memory_state.vnir.base            := config.memory_base; 
                        memory_state.vnir.bounds          := config.memory_bounds / 2;
                        memory_state.swir.base            := config.memory_bounds / 2;
                        memory_state.swir.bounds          := config.memory_bounds * 8 / 10;
                        memory_state.vnir_temp.base       := config.memory_bounds * 8 / 10;
                        memory_state.vnir_temp.bounds     := config.memory_bounds * 9 / 10;
                        memory_state.swir_temp.base       := config.memory_bounds * 9 / 10;
                        memory_state.swir_temp.bounds     := config.memory_bounds;

                        --Setting the output signals to say each subparition is empty
                        memory_state.vnir.filled_base          <= config.memory_base;
                        memory_state.vnir.filled_bounds        <= config.memory_base;
                        memory_state.swir.filled_base          <= config.memory_bounds / 2;
                        memory_state.swir.filled_bounds        <= config.memory_bounds / 2;
                        memory_state.vnir_temp.filled_base     <= config.memory_bounds * 8 / 10;
                        memory_state.vnir_temp.filled_bounds   <= config.memory_bounds * 8 / 10;
                        memory_state.swir_temp.filled_base     <= config.memory_bounds * 9 / 10;
                        memory_state.swir_temp.filled_bounds   <= config.memory_bounds * 9 / 10;

                        --Setting the next state
                        state <= idle;
                    
                    when idle =>
                        --Idle state is really only for monitoring signals that change the state of the memory map
                        if (read_config.read_cmd /= '0') then
                            state <= mpu_check;
                        elsif (number_vnir_rows /= 0 or number_swir_rows /= 0)
                            state <= imaging_config;

                            --Configuring variables for the image
                            swir_rows_left <= number_swir_rows;
                            red_rows_left  <= number_vnir_rows;
                            blue_rows_left <= number_vnir_rows;
                            nir_rows_left  <= number_vnir_rows;

                            vnir_size <= 160 + number_vnir_rows * 3 * 2048 * 10;
                            swir_size <= 160 + number_swir_rows * 512 * 16;
                        end if;

                    when mpu_check =>
                        --TODO: Figure out how to read the incoming data from the SDRAM
                        state <= idle;
                    
                    when imaging_config =>
                        if swir_header_sent = '0' then
                            --Checking to see where the images should go in the partitions
                            if check_overflow(memory_state.vnir, vnir_size) then
                                --Checking to see if the memory is too full, if it is, send it back to idle with error
                                if check_full(memory_state.vnir, vnir_size, memory_state.vnir.base) then
                                    sdram_error <= full;
                                    state <= idle;
                                else
                                    row_address <= memory_state.vnir.base;
                                    vnir_start_address <= memory_state.vnir.base;
                                    memory_state.vnir.bounds <= filled_addresses.vnir_bounds + 10;
                                end if;
                            else
                                --Since the overflow is checked first, no need to check if full
                                row_address <= memory_state.vnir.filled_bounds + 1;
                                vnir_start_address <= memory_state.vnir.filled_bounds + 1;
                                memory_state.vnir.bounds <= filled_addresses.vnir_bounds + 10;
                            end if;

                        else
                            --Checking to see where the images should go in the partitions
                            if check_overflow(memory_state.swir, swir_size) then
                                --Checking to see if the memory is too full, if it is, send it back to idle with error
                                if check_full(memory_state.swir, swir_size, memory_state.swir.base) then
                                    sdram_error <= full;
                                    state <= idle;
                                else
                                    row_address <= memory_state.swir.base;
                                    swir_start_address <= memory_state.swir.base;
                                    memory_state.swir.bounds <= filled_addresses.swir_bounds + 10;
                                end if;
                            else
                                --Since the overflow is checked first, no need to check if full
                                row_address <= memory_state.swir.filled_bounds + 1;
                                swir_start_address <= memory_state.swir.filled_bounds + 1;
                                memory_state.swir.bounds <= filled_addresses.swir_bounds + 10;
                            end if;
                        end if;

                    when row_assign =>
                        --TODO: Figure how to time this
                        state <= idle;
                end case;
            end if;
        end if;

    end process;

end architecture;                