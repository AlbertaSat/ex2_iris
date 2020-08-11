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
        next_row_type       : in sdram_next_row_fed_t;
        next_row_req        : in std_logic;
        output_address      : out sdram_address;

        --Read data to be read from sdram due to mpu interaction
        sdram_error         : out sdram_error_t
    );
end entity memory_map;

architecture rtl of memory_map is
    --FSM signals
    type t_state is (init, img_config_vnir, img_config_swir, imaging);
    signal state, next_state : t_state;

    signal buffer_address : sdram_address;

    --Add/subtract address length signals
    signal vnir_add_length : sdram_address;
    signal swir_add_length : sdram_address;
    signal vnir_temp_add_length : sdram_address;
    signal swir_temp_add_length : sdram_address;

    signal vnir_sub_length : sdram_address;
    signal swir_sub_length : sdram_address;
    signal vnir_temp_sub_length : sdram_address;
    signal swir_temp_sub_length : sdram_address;

    --Start addresses for each band for the image
    signal start_blue_address : sdram_address;
    signal start_red_address  : sdram_address;
    signal start_nir_address  : sdram_address;
    signal start_swir_address : sdram_address;

    signal start_swir_header_address : sdram_address;
    signal start_vnir_header_address : sdram_address;

    --Next addresses out of the memory state
    signal next_blue_address : sdram_address;
    signal next_red_address  : sdram_address;
    signal next_nir_address  : sdram_address;
    signal next_swir_address : sdram_address;

    --Output signal coming from enumerator
    signal inc_blue_address : std_logic;
    signal inc_red_address  : std_logic;
    signal inc_nir_address  : std_logic;
    signal inc_swir_address : std_logic;

    --Various output signals to be Mux'd
    signal row_assign_address : sdram_address;
    signal img_config_address : sdram_address;

    --Img write addresses
    signal vnir_img_start : sdram_address;
    signal vnir_img_end   : sdram_address;

    signal swir_img_start : sdram_address;
    signal swir_img_end   : sdram_address;

    signal vnir_temp_img_start : sdram_address;
    signal vnir_temp_img_end   : sdram_address;

    signal swir_temp_img_start : sdram_address;
    signal swir_temp_img_end   : sdram_address;

    --Partition error signals
    signal vnir_full : std_logic;
    signal swir_full : std_logic;
    signal vnir_temp_full : std_logic;
    signal swir_temp_full : std_logic;

    signal vnir_bad_mpu_check : std_logic;
    signal swir_bad_mpu_check : std_logic;
    signal vnir_temp_bad_mpu_check : std_logic;
    signal swir_temp_bad_mpu_check : std_logic;

    --State controlling variables
    signal write_addresses  : std_logic;
    signal delete_addresses : std_logic;
    signal no_new_rows      : std_logic;

    signal curr_row_type, prev_row_type : sdram_next_row_fed_t;
    signal vnir_header_sent : std_logic;
    signal band_length_set : std_logic;
    signal set_part_bounds : std_logic;

    signal vnir_band_length : sdram_address;
    signal swir_band_length : sdram_address;

    --All these are bounds for the partitions
    signal vhdl_base, vhdl_bounds : sdram_address;
    signal vnir_base, vnir_bounds : sdram_address;
    signal swir_base, swir_bounds : sdram_address;
    signal vnir_temp_base, vnir_temp_bounds : sdram_address;
    signal swir_temp_base, swir_temp_bounds : sdram_address;

    constant VNIR_ROW_LENGTH : integer := 1280; --2048 px/row * 10 b/px / 16 b/address = 1280 address/row
    constant SWIR_ROW_LENGTH : integer := 512;  -- 512 px/row * 16 b/px / 16 b/address = 512 address/row
    constant HEADER_LENGTH   : integer := 16;   -- 160 b/header         / 16 b/address = 16 address/header

    component address_counter is
        generic(increment_size, address_length : integer);
        port(
            clk : std_logic;
            start_address : unsigned(address_length-1 downto 0);
            inc_flag : std_logic;
            
            output_address : unsigned(address_length-1 downto 0)
        );
    end component address_counter;

    component partition_register is
        port(
        clk, reset_n, bounds_write, filled_add, filled_subtract : in std_logic;
        base, bounds, add_length, sub_length : in sdram_address;
        part_out : out partition_t;
        img_start, img_end : out sdram_address;
        full, bad_mpu_check : out std_logic
        );
    end component partition_register;

begin
    --Process responsible assigning the next state at the rising edge
    sig_assign : process(clock) is
    begin
        if (reset_n = '0') then
            state <= init;
            output_address <= to_unsigned(0, 32);
        elsif rising_edge(clock) then
            state <= next_state;
            output_address <= buffer_address;
            prev_row_type <= next_row_type;
        end if;
    end process;

    --Process responsible for assigning the appropriate state
    state_machine : process(start_config, no_new_rows, number_vnir_rows, number_swir_rows) is
    begin
        case state is
            when init =>
                if (start_config <= '1') then
                    next_state <= img_config_vnir;
                else
                    next_state <= init;
                end if;
            when img_config_vnir =>
                if (band_length_set = '1' and next_row_req = '1')  then
                    next_state <= img_config_swir;
                else
                    next_state <= img_config_vnir;
                end if;
            when img_config_swir =>
                if (next_row_req = '1') then
                    next_state <= imaging;
                else
                    next_state <= img_config_swir;
                end if;
            when imaging =>
                if (no_new_rows = '1') then
                    next_state <= img_config_vnir;
                else
                    next_state <= imaging;
                end if;
        end case;
    end process;

    config_process : process (clock, reset_n) is
    begin
        if (reset_n = '0') then
            vnir_band_length <= to_unsigned(0, 32);
            swir_band_length <= to_unsigned(0, 32);
            band_length_set <= '0';
            set_part_bounds <= '0';
        elsif rising_edge(clock) then
            if (state = init and start_config = '1') then
                vhdl_base <= config.memory_base;
                vhdl_bounds <= config.memory_bounds;
                set_part_bounds <= '1';
            end if;
            if (state = img_config_vnir and band_length_set = '0') then
                vnir_band_length <= to_unsigned(number_vnir_rows * VNIR_ROW_LENGTH, 32);
                swir_band_length <= to_unsigned(number_swir_rows * SWIR_ROW_LENGTH, 32);
                band_length_set <= '1';
            end if;
        end if;
    end process; 

    --Address counters for each band
    blue_row_counter : address_counter
        generic map(
            increment_size => VNIR_ROW_LENGTH,
            address_length => 32
        )
        port map(
            clk => clock,
            start_address => start_blue_address,
            inc_flag => inc_blue_address,
            output_address => next_blue_address
        );

    red_row_counter : address_counter
        generic map(
            increment_size => VNIR_ROW_LENGTH,
            address_length => 32
        )
        port map(
            clk => clock,
            start_address => start_red_address,
            inc_flag => inc_red_address,
            output_address => next_red_address
        );

    nir_row_counter : address_counter
        generic map(
            increment_size => VNIR_ROW_LENGTH,
            address_length => 32
        )
        port map(
            clk => clock,
            start_address => start_nir_address,
            inc_flag => inc_nir_address,
            output_address => next_nir_address
        );

    swir_row_counter : address_counter
        generic map(
            increment_size => SWIR_ROW_LENGTH,
            address_length => 32
        )
        port map(
            clk => clock,
            start_address => start_swir_address,
            inc_flag => inc_swir_address,
            output_address => next_swir_address
        );

    --Creating partitions for each type of memory
    vnir_partition_register : partition_register
        port map(
            clk => clock,
            reset_n => reset_n,

            bounds_write => set_part_bounds,
            filled_add => write_addresses,
            filled_subtract => delete_addresses,

            base => vnir_base,
            bounds => vnir_bounds,
            add_length => vnir_add_length,
            sub_length => vnir_sub_length,

            part_out => memory_state.vnir,

            img_start => vnir_img_start,
            img_end => vnir_img_end,

            full => vnir_full,
            bad_mpu_check => vnir_bad_mpu_check
        );
    
    swir_partition_register : partition_register
        port map(
            clk => clock,
            reset_n => reset_n,

            bounds_write => set_part_bounds,
            filled_add => write_addresses,
            filled_subtract => delete_addresses,

            base => swir_base,
            bounds => swir_bounds,
            add_length => swir_add_length,
            sub_length => swir_sub_length,

            part_out => memory_state.swir,
            
            img_start => swir_img_start,
            img_end => swir_img_end,

            full => swir_full,
            bad_mpu_check => swir_bad_mpu_check
        );
    
    vnir_temp_partition_register : partition_register
        port map(
            clk => clock,
            reset_n => reset_n,

            bounds_write => set_part_bounds,
            filled_add => write_addresses,
            filled_subtract => delete_addresses,

            base => vnir_temp_base,
            bounds => vnir_temp_bounds,
            add_length => vnir_temp_add_length,
            sub_length => vnir_temp_sub_length,

            part_out => memory_state.vnir_temp,

            img_start => vnir_temp_img_start,
            img_end => vnir_temp_img_end,

            full => vnir_temp_full,
            bad_mpu_check => vnir_temp_bad_mpu_check
        );
        
    swir_temp_partition_register : partition_register
        port map(
            clk => clock,
            reset_n => reset_n,

            bounds_write => set_part_bounds,
            filled_add => write_addresses,
            filled_subtract => delete_addresses,

            base => swir_temp_base,
            bounds => swir_temp_bounds,
            add_length => swir_temp_add_length,
            sub_length => swir_temp_sub_length,

            part_out => memory_state.swir_temp,

            img_start => swir_temp_img_start,
            img_end => swir_temp_img_end,

            full => swir_temp_full,
            bad_mpu_check => swir_temp_bad_mpu_check
        );

    vnir_base <= config.memory_base;
    vnir_bounds <= resize(config.memory_bounds * 8 / 16, 32);
    swir_base <= resize(config.memory_bounds * 8 / 16 + 1, 32);
    swir_bounds <= resize(config.memory_bounds * 14 / 16, 32);
    vnir_temp_base <= resize(config.memory_bounds * 14 / 16 + 1, 32);
    vnir_temp_base <= resize(config.memory_bounds * 15 / 16, 32);
    swir_temp_base <= resize(config.memory_bounds * 15 / 16 + 1, 32);
    swir_temp_base <= config.memory_bounds;

    --Creating the start addresses for each counter
    start_swir_header_address <= swir_img_start;
    start_vnir_header_address <= vnir_img_start;

    start_blue_address <= vnir_img_start + HEADER_LENGTH;
    start_red_address  <= vnir_img_start + HEADER_LENGTH + vnir_band_length; --Adding room for the blue band
    start_nir_address  <= resize(vnir_img_start + HEADER_LENGTH + vnir_band_length * 2, 32); --Room for both blue and red
    start_swir_address <= swir_img_start + HEADER_LENGTH;
    
    no_new_rows <= '1' when (next_blue_address = start_red_address and next_red_address = start_nir_address and next_nir_address = vnir_img_end and next_swir_address = swir_img_end) else '0';

    --Increment when the next row is requested
    inc_nir_address  <= '1' when (next_row_req = '1' and prev_row_type = nir_row)  else '0';
    inc_red_address  <= '1' when (next_row_req = '1' and prev_row_type = red_row)  else '0';
    inc_blue_address <= '1' when (next_row_req = '1' and prev_row_type = blue_row) else '0';
    inc_swir_address <= '1' when (next_row_req = '1' and prev_row_type = swir_row) else '0';

    with next_row_type select row_assign_address <=
        next_swir_address when swir_row,
        next_nir_address  when  nir_row,
        next_red_address  when  red_row,
        next_blue_address when blue_row,
        to_unsigned(0, 32) when  no_row;

    img_config_address <= vnir_img_start when state = img_config_vnir else
                          swir_img_start when state = img_config_swir else
                          to_unsigned(0, 32);  
    
    buffer_address <= row_assign_address when state = imaging else
                      img_config_address when state = img_config_vnir or state = img_config_swir else
                      to_unsigned(0, 32);    
    
end architecture;