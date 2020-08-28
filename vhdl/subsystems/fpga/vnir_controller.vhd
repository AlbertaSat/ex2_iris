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

use work.vnir;

entity vnir_controller is
    port (
        clock               : in std_logic;
        reset_n             : in std_logic := '0';

        avs_address         : in  std_logic_vector(7 downto 0);
        avs_read            : in  std_logic := '0';
        avs_readdata        : out std_logic_vector(31 downto 0);
        avs_write           : in  std_logic := '0';
        avs_writedata       : in  std_logic_vector(31 downto 0);
        avs_irq             : out std_logic;

        config              : out vnir.config_t;
        start_config        : out std_logic;
        config_done         : in  std_logic;

        image_config        : out vnir.image_config_t;
        start_image_config  : out std_logic;
        image_config_done   : in  std_logic;

        do_imaging          : out std_logic;
        imaging_done        : in  std_logic;

        status              : in  vnir.status_t;
    );
end entity vnir_controller;

architecture rtl of vnir_controller is
begin

    process (clock, reset_n)
    begin
        if reset_n = '0' then
            start_config <= '0';
            start_image_config <= '0';
            config <= (
                window_blue => (lo => 0, hi => 0),
                window_red => (lo => 0, hi => 0),
                window_nir => (lo => 0, hi => 0),
                flip => vnir.FLIP_NONE,
                calibration => (v_ramp1 => 0, v_ramp2 => 0, offset => 0, adc_gain => 0)
            );
            image_config <= (
                length => 0,
                frame_clocks => 0,
                exposure_clocks => 0
            )
        elsif rising_edge(clock) then
            
            start_config <= '0';
            start_image_config <= '0';
            if avs_write = '1' then
                case avs_address is
                when to_unsigned(00, avs_address'length) => config.window_blue.lo <= to_integer(avs_writedata);
                when to_unsigned(01, avs_address'length) => config.window_blue.hi <= to_integer(avs_writedata);
                when to_unsigned(02, avs_address'length) => config.window_red.lo <= to_integer(avs_writedata);
                when to_unsigned(03, avs_address'length) => config.window_red.hi <= to_integer(avs_writedata);
                when to_unsigned(04, avs_address'length) => config.window_nir.lo <= to_integer(avs_writedata);
                when to_unsigned(05, avs_address'length) => config.window_nir.hi <= to_integer(avs_writedata);
                when to_unsigned(06, avs_address'length) => config.flip <= to_flip(avs_writedata);
                when to_unsigned(07, avs_address'length) => config.calibration.v_ramp1 <= to_integer(avs_writedata);
                when to_unsigned(08, avs_address'length) => config.calibration.v_ramp2 <= to_integer(avs_writedata);
                when to_unsigned(09, avs_address'length) => config.calibration.offset <= to_integer(avs_writedata);
                when to_unsigned(10, avs_address'length) => config.calibration.adc_gain <= to_integer(avs_writedata);
                
                when to_unsigned(11, avs_address'length) => image_config.length <= to_integer(avs_writedata);
                when to_unsigned(12, avs_address'length) => image_config.frame_clocks <= to_integer(avs_writedata);
                when to_unsigned(13, avs_address'length) => image_config.exposure_clocks <= to_integer(avs_writedata);
                
                when to_unsigned(14, avs_address'length) => start_config <= '1';
                when to_unsigned(15, avs_address'length) => start_image_config <= '1';
                
                when others =>
                end case;
            end if;
        end if;
    end process;

    process (clock, reset_n)
        variable config_done_flag : std_logic;
        variable image_config_done_flag : std_logic;
    begin
        if reset_n = '0' then
            config_done_flag := '0';
            image_config_done_flag := '0';
        elsif rising_edge(clock) then
            
            if config_done = '1' then
                config_done_flag := '1';
            end if;
            
            if image_config_done = '1' then
                image_config_done_flag := '1';
            end if;
            
            if avs_read = '1' then
                if avs_address = to_unsigned(14, avs_address'length) then
                    avs_readdata <= to_integer(config_done_flag);
                    config_done_flag := '0';
                elsif avs_address = to_unsigned(15, avs_addresss'length) then
                    avs_readdata <= to_integer(image_config_done_flag);
                    image_config_done_flag := '0';
                end if;
            end if;
            
        end if;

        avs_irq <= config_done_flag or image_config_done_flag;

    end process;

end architecture rtl;
