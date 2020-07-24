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
        img_config_done     : out std_logic;

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

    --Start addresses for each band for the image
    signal start_blue_address : unsigned(32 downto 0);
    signal start_red_address  : unsigned(32 downto 0);
    signal start_nir_address  : unsigned(32 downto 0);
    signal start_swir_address : unsigned(32 downto 0);

    --Next addresses out of the memory state
    signal next_blue_address : unsigned(32 downto 0);
    signal next_red_address  : unsigned(32 downto 0);
    signal next_nir_address  : unsigned(32 downto 0);
    signal next_swir_address : unsigned(32 downto 0);

    --Output signal coming from enumerator
    signal inc_blue_address : std_logic;
    signal inc_red_address  : std_logic;
    signal inc_nir_address  : std_logic;
    signal inc_swir_address : std_logic;

    component address_counter is
        generic(increment_size, address_length : integer);
        port(
            clk : std_logic;
            start_address : unsigned(address_length-1 downto 0);
            inc_flag : std_logic;
            
            output_address : unsigned(address_length-1 downto 0)
        );
    end component address_counter;

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
    --Address counters for each band
    blue_row_counter : address_counter
        generic map(
            increment_size => 1280,     --2048 px/row * 10 b/px / 16 b/address = 1280 address/row
            address_length => 32
        );
        port map(
            clk => clock,
            start_address => start_blue_address,
            inc_flag => inc_blue_address,
            output_address => next_blue_address
        );

    red_row_counter : address_counter
        generic map(
            increment_size => 1280,     --2048 px/row * 10 b/px / 16 b/address = 1280 address/row
            address_length => 32
        );
        port map(
            clk => clock,
            start_address => start_red_address,
            inc_flag => inc_red_address,
            output_address => next_red_address
        );

    nir_row_counter : address_counter
        generic map(
            increment_size => 1280,     --2048 px/row * 10 b/px / 16 b/address = 1280 address/row
            address_length => 32
        );
        port map(
            clk => clock,
            start_address => start_nir_address,
            inc_flag => inc_nir_address,
            output_address => next_nir_address
        );

    swir_row_counter : address_counter
        generic map(
            increment_size => 512,     --512 px/row * 16 b/px / 16 b/address = 512 address/row
            address_length => 32
        );
        port map(
            clk => clock,
            start_address => start_swir_address,
            inc_flag => inc_swir_address,
            output_address => next_swir_address
        );
    
    

end architecture;                