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

use work.vnir;
use work.sensor_configurer_pkg;

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

        status              : in  vnir.status_t
    );
end entity vnir_controller;

architecture rtl of vnir_controller is

    pure function read_integer(bits : std_logic_vector) return integer is
    begin
        return to_integer(signed(bits));
    end function read_integer;

    pure function read_flip(bits : std_logic_vector) return vnir.flip_t is
    begin
        case bits is
            when x"00000000" => return sensor_configurer_pkg.FLIP_NONE;
            when x"00000001" => return sensor_configurer_pkg.FLIP_X;
            when x"00000002" => return sensor_configurer_pkg.FLIP_Y;
            when x"00000003" => return sensor_configurer_pkg.FLIP_XY;
            when others =>
                report "Invalid bit pattern given to read_flip()" severity failure;
                return sensor_configurer_pkg.FLIP_NONE;
        end case;
    end function read_flip;

begin

    process (clock, reset_n)
    begin
        if reset_n = '0' then
            start_config <= '0';
            start_image_config <= '0';
            config <= (
                window_red => (lo => 0, hi => 0),
                window_nir => (lo => 0, hi => 0),
                window_blue => (lo => 0, hi => 0),
                flip => sensor_configurer_pkg.FLIP_NONE,
                calibration => (v_ramp1 => 0, v_ramp2 => 0, offset => 0, adc_gain => 0)
            );
            image_config <= (
                length => 0,
                frame_clocks => 0,
                exposure_clocks => 0
            );
        elsif rising_edge(clock) then
            
            start_config <= '0';
            start_image_config <= '0';
            if avs_write = '1' then
                case avs_address is
                when x"00" => config.window_red.lo         <= read_integer(avs_writedata);
                when x"01" => config.window_red.hi         <= read_integer(avs_writedata);
                when x"02" => config.window_nir.lo         <= read_integer(avs_writedata);
                when x"03" => config.window_nir.hi         <= read_integer(avs_writedata);
                when x"04" => config.window_blue.lo        <= read_integer(avs_writedata);
                when x"05" => config.window_blue.hi        <= read_integer(avs_writedata);
                when x"06" => config.flip                  <= read_flip(avs_writedata);
                when x"07" => config.calibration.v_ramp1   <= read_integer(avs_writedata);
                when x"08" => config.calibration.v_ramp2   <= read_integer(avs_writedata);
                when x"09" => config.calibration.offset    <= read_integer(avs_writedata);
                when x"0A" => config.calibration.adc_gain  <= read_integer(avs_writedata);
                
                when x"0B" => image_config.length          <= read_integer(avs_writedata);
                when x"0C" => image_config.frame_clocks    <= read_integer(avs_writedata);
                when x"0D" => image_config.exposure_clocks <= read_integer(avs_writedata);
                
                when x"0E" => start_config                 <= '1';
                when x"0F" => start_image_config           <= '1';
                
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
                if avs_address = x"0E" then
                    avs_readdata <= (0 => config_done_flag, others => '0');
                    config_done_flag := '0';
                elsif avs_address = x"0F" then
                    avs_readdata <= (0 => image_config_done_flag, others => '0');
                    image_config_done_flag := '0';
                end if;
            end if;
            
        end if;

        avs_irq <= config_done_flag or image_config_done_flag;

    end process;

end architecture rtl;
