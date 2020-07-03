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
        reset               : in std_logic;

        --SDRAM config signals to and from the FPGA
        config              : in sdram_config_to_sdram_t;
        config_done         : out std_logic;
        filled_addresses    : out sdram_config_from_sdram_t;

        --Image Config signals
        number_swir_rows    : in integer range 0 to integer'high;
        number_vnir_rows    : in integer range 0 to integer'high;
        
        --Ouput image row address config
        next_row_type       : in sdram_next_row_fed;
        row_address         : out integer range 0 to integer'high;

        --Read data to be read from sdram due to mpu interaction
        sdram_error         : out sdram_error_t;
        read_data           : in std_logic; --TODO: Define wtf this is
    );
end entity memory_map;

architecture rtl of memory_map is
    --FSM signals
    type t_state is (init, idle, row_assign, mpu_check);
    signal state : t_state;


    --Signals defining the VHDL internal partitions in the memory
    variable vnir_min       : integer;
    variable vnir_max       : integer;

    variable swir_min       : integer;
    variable swir_max       : integer;

    variable vnir_temp_min  : integer;
    variable vnir_temp_max  : integer;

    variable swir_temp_min  : integer;
    variable swir_temp_max  : integer;

    --Variables representing the part of each partition that is currently filled with data
    subtype locs is array (1 downto 0) of integer;

    variable vnir_locs      : locs;
    variable swir_locs      : locs;
    variable vnir_temp_locs : locs;
    variable swir_temp_locs : locs;

begin

    --The main process for everything
    main_process : process (clock, reset) is

    begin
        if (reset = '1') then
            --If reset is asserted, initializing and writing all maps to 0
            state <= init;

            vnir_locs <= (0,0);
            swir_locs <= (0,0);
            vnir_temp_locs <= (0,0);
            swir_temp_locs <= (0,0);
        end if;

        if rising_edge(clock) then
            case state is
                when init =>
                    --Creating the minimum and maximum locations for vnir and swir images
                    --TODO: Create a mapping process with the sizes of each taken into account
                    vnir_min        <= config.memory_base; 
                    vnir_max        <= config.memory_bounds / 2;
                    swir_min        <= vnir_max + 1;
                    swir_max        <= config.memory_bounds * 8 / 10;
                    vnir_temp_min   <= swir_max + 1;
                    vnir_temp_max   <= config.memory_bounds * 9 / 10;
                    swir_temp_min   <= vnir_temp_max + 1;
                    swir_temp_max   <= config.memory_bounds;

                    --Setting the currently filled addresses to the lowest possible values
                    vnir_locs       <= (vnir_min, vnir_min)
                    swir_locs       <= (swir_min, swir_min)
                    vnir_temp_locs  <= (vnir_temp_min, vnir_temp_min)
                    swir_temp_locs  <= (swir_temp_min, swir_temp_min)

                    --Setting the output signals to mirror the variables
                    filled_addresses.vnir_base          <= vnir_locs(0);
                    filled_addresses.vnir_bounds        <= vnir_locs(1);
                    filled_addresses.swir_base          <= swir_locs(0);
                    filled_addresses.swir_bounds        <= swir_locs(1);
                    filled_addresses.vnir_temp_base     <= vnir_temp_locs(0);
                    filled_addresses.vnir_temp_bounds   <= vnir_temp_locs(1);
                    filled_addresses.swir_temp_base     <= swir_temp_locs(0);
                    filled_addresses.swir_temp_bounds   <= swir_temp_locs(1);

                    --Setting the next state
                    state <= idle;
                    config_done <= '1';
                
                when idle =>
                    --Idle state is really only for monitoring signals that change the state of the memory map
                    if (mpu_mem_change /= 0) then
                        state <= mpu_check;
                    elsif (next_row_type /= NO_ROW)
                        state <= row_assign;
                    end if;

                when mpu_check =>
                    --TODO: Figure out how to read the incoming data from the SDRAM
                    state <= idle;
                
                when row_assign =>
                    --TODO: Figure how to time this
                    state <= idle;
            end case;
        end if;

    end process;

end architecture;                