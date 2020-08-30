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

use work.sdram_types.all;

entity sdram_controller is
    port (
        clock               : in std_logic;
        reset_n             : in std_logic := '0';

        avs_address         : in  std_logic_vector(7 downto 0);
        avs_read            : in  std_logic := '0';
        avs_readdata        : out std_logic_vector(31 downto 0);
        avs_write           : in  std_logic := '0';
        avs_writedata       : in  std_logic_vector(31 downto 0);
        avs_irq             : out std_logic;

        swir_num_rows       : out integer;
        vnir_num_rows       : out integer;

        timestamp           : out timestamp_t;
        mpu_memory_change   : out sdram_address_list_t;
        config_to_sdram     : out sdram_config_to_sdram_t;
        config_from_sdram   : in  sdram_config_from_sdram_t;
        config_done         : in  std_logic;

        sdram_busy          : in std_logic;
        sdram_error         : in stdram_error_t;
    );
end entity sdram_controller;

architecture rtl of sdram_controller is
    
    pure function read_integer(bits : std_logic_vector) return integer is
    begin
        return to_integer(signed(bits));
    end function read_integer;

begin
    
    process (clock, reset_n)
        variable config_done_reg : std_logic;
        variable config_done_irq : std_logic;
    begin
        if reset_n = '0' then
            config_to_sdram <= (memory_base => 0, memory_bounds => 0);
            swir_num_rows   <= 0;
            vnir_num_rows   <= 0;
            config_done_reg := 0;
            config_done_irq := 0;
        elsif rising_edge(clock) then

            start_config <= '0';

            if avs_write = '1' then
                case avs_address is
                when x"00" => config_to_sdram.memory_base   <= read_integer(avs_writedata);
                when x"01" => config_to_sdram.memory_bounds <= read_integer(avs_writedata);
                when x"02" => swir_num_rows                 <= read_integer(avs_writedata);
                when x"03" => vnir_num_rows                 <= read_integer(avs_writedata);
                when x"04" => timestamp                     <= read_timestamp(avs_writedata);
                when x"05" => mpu_memory_change             <= read_addr_list(avs_writedata);
                
                when x"06" => start_config <= '1'; config_done_reg <= '0';
                when others =>
                end case;
            elsif avs_read = '1' then
                case avs_address is
                when x"07" => avs_readdata <= to_l32(config_done_reg); config_done_irq := '0';

                when x"08" => avs_readdata <= to_l32(config_from_sdram.swir_base);
                when x"09" => avs_readdata <= to_l32(config_from_sdram.swir_bounds);
                when x"0a" => avs_readdata <= to_l32(config_from_sdram.swir_temp_base);
                when x"0b" => avs_readdata <= to_l32(config_from_sdram.swir_temp_bounds);
                when x"0c" => avs_readdata <= to_l32(config_from_sdram.vnir_base);
                when x"0d" => avs_readdata <= to_l32(config_from_sdram.vnir_bounds);
                when x"0e" => avs_readdata <= to_l32(config_from_sdram.vnir_temp_base);
                when x"0f" => avs_readdata <= to_l32(config_from_sdram.vnir_temp_bounds);
                when x"10" => avs_readdata <= to_l32(sdram_busy);
                when x"11" => avs_readdata <= to_l32(sdram_error);
                when others =>
                end case;
            end if;

            if config_done = '1' then
                config_done_reg := '1';
                config_done_irq := '1';
            end if;

        end if;

        avs_irq <= config_done_irq;
    
    end process;
    
end architecture rtl;