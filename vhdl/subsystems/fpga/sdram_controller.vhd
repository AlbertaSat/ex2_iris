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
use work.fpga_types.all;

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
        start_config        : out std_logic;
        config_done         : in  std_logic;
        img_config_done     : in  std_logic;

        sdram_busy          : in std_logic;
        sdram_error         : in sdram_error_t
    );
end entity sdram_controller;

architecture rtl of sdram_controller is
    
    pure function read_integer(bits : std_logic_vector) return integer is
    begin
        return to_integer(signed(bits));
    end function read_integer;

    pure function read_timestamp(bits : std_logic_vector) return timestamp_t is
    begin
        return timestamp_t(unsigned(bits));
    end function read_timestamp;
    
    pure function to_l32(b : std_logic) return std_logic_vector is
        variable re : std_logic_vector(31 downto 0);
    begin
        re := (0 => b, others => '0');
        return re;
    end function to_l32;

    pure function to_l32(i : integer) return std_logic_vector is
    begin
        return std_logic_vector(to_signed(i, 32));
    end function to_l32;

    pure function to_l32(e : sdram_error_t) return std_logic_vector is
    begin
        case e is
            when SDRAM_NO_ERROR         => return x"00000000";
            when SDRAM_FULL             => return x"00000001";
            when SDRAM_MPU_CHECK_FAILED => return x"00000002";
        end case;
    end function to_l32;

begin
    
    process (clock, reset_n)
        variable config_done_reg : std_logic;
        variable config_done_irq : std_logic;
    begin
        if reset_n = '0' then
            config_to_sdram <= (memory_base => 0, memory_bounds => 0);
            swir_num_rows   <= 0;
            vnir_num_rows   <= 0;
            config_done_reg := '0';
            config_done_irq := '0';
        elsif rising_edge(clock) then

            start_config <= '0';

            if avs_write = '1' then
                case avs_address is
                when x"00" => config_to_sdram.memory_base   <= read_integer(avs_writedata);
                when x"01" => config_to_sdram.memory_bounds <= read_integer(avs_writedata);
                when x"02" => swir_num_rows                 <= read_integer(avs_writedata);
                when x"03" => vnir_num_rows                 <= read_integer(avs_writedata);
                when x"04" => timestamp                     <= read_timestamp(avs_writedata);
                when x"05" => mpu_memory_change(0)          <= read_integer(avs_writedata);
                when x"06" => mpu_memory_change(1)          <= read_integer(avs_writedata);
                when x"07" => mpu_memory_change(2)          <= read_integer(avs_writedata);
                when x"08" => mpu_memory_change(3)          <= read_integer(avs_writedata);
                when x"09" => mpu_memory_change(4)          <= read_integer(avs_writedata);
                when x"0a" => mpu_memory_change(5)          <= read_integer(avs_writedata);
                when x"0b" => mpu_memory_change(6)          <= read_integer(avs_writedata);
                when x"0c" => mpu_memory_change(7)          <= read_integer(avs_writedata);
                when x"0d" => mpu_memory_change(8)          <= read_integer(avs_writedata);
                when x"0e" => mpu_memory_change(9)          <= read_integer(avs_writedata);
                when x"0f" => mpu_memory_change(10)         <= read_integer(avs_writedata);
                
                when x"10" => start_config <= '1'; config_done_reg := '0';
                when others =>
                end case;
            elsif avs_read = '1' then
                case avs_address is
                when x"11" => avs_readdata <= to_l32(config_done_reg); config_done_irq := '0';

                when x"12" => avs_readdata <= to_l32(config_from_sdram.swir_base);
                when x"13" => avs_readdata <= to_l32(config_from_sdram.swir_bounds);
                when x"14" => avs_readdata <= to_l32(config_from_sdram.swir_temp_base);
                when x"15" => avs_readdata <= to_l32(config_from_sdram.swir_temp_bounds);
                when x"16" => avs_readdata <= to_l32(config_from_sdram.vnir_base);
                when x"17" => avs_readdata <= to_l32(config_from_sdram.vnir_bounds);
                when x"18" => avs_readdata <= to_l32(config_from_sdram.vnir_temp_base);
                when x"19" => avs_readdata <= to_l32(config_from_sdram.vnir_temp_bounds);
                when x"1a" => avs_readdata <= to_l32(sdram_busy);
                when x"1b" => avs_readdata <= to_l32(sdram_error);
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