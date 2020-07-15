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
        filled_addresses    : out sdram_partitions_t;

        start_config        : in std_logic;
        config_done         : out std_logic;

        --Image Config signals
        number_swir_rows    : in integer range 0 to integer'high;
        number_vnir_rows    : in integer range 0 to integer'high;

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
    signal state : t_state;

    --Creating a function that automatically does memory placing
    function place_data(filled_addresses : sdram_partitions_t, bounds : sdram_partitions_t)
begin

    --The main process for everything
    main_process : process (clock, reset) is
        --A variable defining the VHDL internal partitions in the memory
        variable sdram_partitions : sdram_partitions_t;

        --Variables detailing the amount of rows left in the imaging proces
        variable vnir_rows_left   : integer             := 0;
        variable swir_rows_left   : integer             := 0;

        variable swir_header_sent : std_logic           := '0';
    begin
        if rising_edge(clock) then
            if (reset_n = '0') then
                --If reset is asserted, initializing and writing everything to 0
                state <= init;

                sdram_error <= NO_ERROR;
                row_address <= 0;
                config_done <= '0';
                filled_addresses <= (
                    swir_base           => 0,
                    swir_bounds         => 0,
                    swir_temp_base      => 0,
                    swir_temp_bounds    => 0,
                    vnir_base           => 0,
                    vnir_bounds         => 0,
                    vnir_temp_base      => 0,
                    vnir_temp_bounds    => 0
                );
                sdram_partition := (
                    swir_base           => 0,
                    swir_bounds         => 0,
                    swir_temp_base      => 0,
                    swir_temp_bounds    => 0,
                    vnir_base           => 0,
                    vnir_bounds         => 0,
                    vnir_temp_base      => 0,
                    vnir_temp_bounds    => 0
                );
            
            else
                case state is
                    when init =>
                        --Init just waits for start_config signal to start the configuration of the SDRAM
                        if start_config = '1' then
                            state <= sys_config;
                        end if;

                    when sys_config =>
                        --Creating the minimum and maximum locations for vnir and swir images
                        --TODO: Create a mapping process with the sizes of each taken into account
                        sdram_parition.vnir_base            := config.memory_base; 
                        sdram_parition.vnir_bounds          := config.memory_bounds / 2;
                        sdram_parition.swir_base            := vnir_max + 1;
                        sdram_parition.swir_bounds          := config.memory_bounds * 8 / 10;
                        sdram_parition.vnir_temp_base       := swir_max + 1;
                        sdram_parition.vnir_temp_bounds     := config.memory_bounds * 9 / 10;
                        sdram_parition.swir_temp_base       := vnir_temp_max + 1;
                        sdram_parition.swir_temp_bounds     := config.memory_bounds;

                        --Setting the output signals to say each subparition is empty
                        filled_addresses.vnir_base          <= sdram_parition.vnir_base;
                        filled_addresses.vnir_bounds        <= sdram_parition.vnir_base;
                        filled_addresses.swir_base          <= sdram_parition.swir_base;
                        filled_addresses.swir_bounds        <= sdram_parition.swir_base;
                        filled_addresses.vnir_temp_base     <= sdram_parition.vnir_temp_base;
                        filled_addresses.vnir_temp_bounds   <= sdram_parition.vnir_temp_base;
                        filled_addresses.swir_temp_base     <= sdram_parition.swir_temp_base;
                        filled_addresses.swir_temp_bounds   <= sdram_parition.swir_temp_base; 

                        --Setting the next state
                        state <= idle;
                        config_done <= '1';
                    
                    when idle =>
                        --Idle state is really only for monitoring signals that change the state of the memory map
                        if (read_config.read_cmd /= '0') then
                            state <= mpu_check;
                        elsif (number_vnir_rows /= 0 or number_swir_rows /= 0)
                            state <= imaging_config;
                        end if;

                    when mpu_check =>
                        --TODO: Figure out how to read the incoming data from the SDRAM
                        state <= idle;
                    
                    when imaging_config =>
                        if swir_header_sent = '0' then
                            --Using the rows in to configure the amount of rows left 
                            swir_rows_left := number_swir_rows;
                            vnir_rows_left := number_vnir_rows;

                            row_address := (filled_addresses.vnir_bounds;

                            filled_addresses.vnir_bounds <= filled_addresses.vnir_bounds + 10;
                        else
                            row_address := filled_addresses.vnir_bounds;

                            filled_addresses.swir_bounds <= filled_addresses.swir_bounds + 10;
                            state <= row_assign;
                        end if;

                    when row_assign =>
                        --TODO: Figure how to time this
                        state <= idle;
                end case;
            end if;
        end if;

    end process;

end architecture;                