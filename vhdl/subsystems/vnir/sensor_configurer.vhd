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

use work.vnir_types.all;
use work.spi_types.all;

-- TODO: reset sensor
-- TODO: Should probably have config delays here


entity sensor_configurer is
port (	
    clock           : in std_logic;
    reset_n         : in std_logic;
    config          : in vnir_config_t;
    start_config    : in std_logic;
    config_done     : out std_logic;	
    spi_out         : out spi_from_master_t;
    spi_in          : in spi_to_master_t;
    sensor_reset    : out std_logic
);
end entity sensor_configurer;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vnir_types.all;
use work.logic_types.all;


package vnir_sensor_config_pkg is

    pure function l8_instructions(l8 : logic8_t; addr : integer) return logic16_vector_t;
    pure function i8_instructions(i8 : integer; addr : integer) return logic16_vector_t;
    pure function l16_instructions(l16 : logic16_t; addr : integer) return logic16_vector_t;
    pure function i16_instructions(i16 : integer; addr : integer) return logic16_vector_t;
    
    pure function window_instructions(window : vnir_window_t; index : integer) return logic16_vector_t;
    pure function window_instructions(config : vnir_config_t) return logic16_vector_t;
    pure function flip_instructions(flip : vnir_flip_t) return logic16_vector_t;
    pure function misc_instructions(flags : std_logic_vector) return logic16_vector_t;
    pure function n_channels_instructions(n_channels : integer) return logic16_vector_t;
    pure function calibration_instructions(config : vnir_config_t) return logic16_vector_t;
    pure function bit_mode_instructions(pixel_bits : integer) return logic16_vector_t;
    pure function pll_instructions(sensor_clock_MHz : integer; pixel_bits : integer) return logic16_vector_t;
    pure function undocumented_instructions return logic16_vector_t;
    pure function all_instructions (config : vnir_config_t) return logic16_vector_t;

end package vnir_sensor_config_pkg;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vnir_types.all;
use work.spi_types.all;
use work.vnir_sensor_config_pkg.all;
use work.logic_types.all;

architecture rtl of sensor_configurer is
    component spi_master is
    generic (
        slaves  : integer;  
        d_width : integer
    );
    port (
        clock   : in     std_logic;                             
        reset_n : in     std_logic;                             
        enable  : in     std_logic;                             
        cpol    : in     std_logic;                             
        cpha    : in     std_logic;                             
        cont    : in     std_logic;                             
        clk_div : in     integer;                               
        addr    : in     integer;                               
        tx_data : in     logic16_t;  
        miso    : in     std_logic;                             
        sclk    : buffer std_logic;                             
        ss_n    : buffer std_logic_vector(0 downto 0);   
        mosi    : out    std_logic;                             
        busy    : out    std_logic;                             
        rx_data : out    logic16_t
    ); 
    end component;

    signal spi_enable : std_logic;
    signal spi_cont : std_logic;
    signal spi_tx_data : std_logic_vector(15 downto 0);
    signal spi_busy : std_logic;
    signal spi_ss_n : std_logic;
begin

    main_process : process
        type state_t is (RESET, IDLE, TRANSMIT, TRANSMIT_FINISH);
        variable state : state_t;

        variable i : integer;
        variable spi_busy_prev : std_logic;

        constant n_spi_instructions : integer := 33;  -- Length of all_instructions() output
        variable instructions : logic16_vector_t(n_spi_instructions-1 downto 0);
    begin
        wait until rising_edge(clock);
        config_done <= '0';
        spi_enable <= '0';
        spi_cont <= '0';
        if (reset_n = '0') then
            state := RESET;
        end if;

        case state is
        when RESET =>
            state := IDLE;
        when IDLE =>
            if start_config = '1' then
                state := TRANSMIT;
                instructions := all_instructions(config);
                i := 0;
                spi_tx_data <= instructions(i);
            end if;
        when TRANSMIT =>
            spi_enable <= '1';
            spi_cont <= '1';
            if (spi_busy = '1' and spi_busy_prev = '0') then
                if (i = n_spi_instructions - 1) then
                    state := TRANSMIT_FINISH;
                else
                    i := i + 1;
                    spi_tx_data <= instructions(i);
                end if;
            end if;
        when TRANSMIT_FINISH =>
            if spi_busy = '0' then
                state := IDLE;
                config_done <= '1';
            end if;
        end case;
        
        spi_busy_prev := spi_busy;

    end process main_process;

    -- Invert ss line to make it active-high as per the CMV2000 datasheet
    spi_out.slave_select <= not spi_ss_n;
    
    spi_controller : spi_master generic map(
        slaves      =>	1,
        d_width     =>	16
    ) port map(
        clock       =>	clock,
        reset_n     =>	reset_n,
        enable      =>	spi_enable,
        cpol        =>	'0',        -- chosen based on CMV2000 datasheet
        cpha        =>	'0',        -- ^
        cont        =>	spi_cont,
        clk_div     =>	0,
        addr        =>	0,
        tx_data     =>	spi_tx_data,
        miso        =>	spi_in.data,
        sclk        =>	spi_out.clock,
        ss_n(0)     =>	spi_ss_n,
        mosi        =>	spi_out.data,
        busy        =>	spi_busy,
        rx_data     =>	open
    );

end rtl;


package body vnir_sensor_config_pkg is

    pure function l8_instructions(l8 : logic8_t; addr : integer) return logic16_vector_t is
        variable instructions : logic16_vector_t(0 downto 0);
    begin
        instructions(0) := '1' & to_logic7(addr) & l8;
        return instructions;
    end function l8_instructions;

    pure function i8_instructions(i8 : integer; addr : integer) return logic16_vector_t is
    begin
        return l8_instructions(to_logic8(i8), addr);
    end function i8_instructions;

    pure function l16_instructions(l16 : logic16_t; addr : integer) return logic16_vector_t is
        variable instructions : logic16_vector_t(2-1 downto 0);
    begin
        instructions(1) := '1' & to_logic7(addr + 0) & l16(7 downto 0);
        instructions(0) := '1' & to_logic7(addr + 1) & l16(15 downto 8);
        return instructions;
    end function l16_instructions;

    pure function i16_instructions(i16 : integer; addr : integer) return logic16_vector_t is
    begin
        return l16_instructions(to_logic16(i16), addr);
    end function i16_instructions;

    pure function window_instructions(window : vnir_window_t; index : integer) return logic16_vector_t is
        constant addr_low_base : integer := 3;
        constant addr_size_base : integer := 19;
        constant addr_stride : integer := 2;
    begin
        return i16_instructions(window.lo, addr_low_base + addr_stride * index)
             & i16_instructions(size(window), addr_size_base + addr_stride * index);
    end function window_instructions;

    pure function window_instructions(config : vnir_config_t) return logic16_vector_t is
        constant addr_total_rows : integer := 1;
    begin
        return i16_instructions(total_rows(config), addr_total_rows)
             & window_instructions(config.window_red, 0)
             & window_instructions(config.window_blue, 1)
             & window_instructions(config.window_nir, 2);
    end function window_instructions;

    pure function flip_instructions(flip : vnir_flip_t) return logic16_vector_t is
        constant addr_flip : integer := 40;
    begin
        case flip is
        when FLIP_NONE => return i8_instructions(0, addr_flip);
        when FLIP_X => return i8_instructions(1, addr_flip);
        when FLIP_Y => return i8_instructions(2, addr_flip);
        when FLIP_XY => return i8_instructions(3, addr_flip);
        end case;
    end function flip_instructions;

    constant EXTERNAL_EXPOSURE : std_logic_vector(3-1 downto 0) := "001";
    constant DUAL_EXPOSURE     : std_logic_vector(3-1 downto 0) := "010";
    constant DUMMY_INSERTION   : std_logic_vector(3-1 downto 0) := "100";

    pure function to_std_logic(b : boolean) return std_logic is
    begin
        if b then return '1'; else return '0'; end if;
    end function to_std_logic;

    pure function misc_instructions(flags : std_logic_vector) return logic16_vector_t is
        constant addr_misc : integer := 41;
        variable dummy_insertion_bit : std_logic;
        variable dual_exposure_bit : std_logic;
        variable external_exposure_bit : std_logic;
        variable encoded_flags : logic8_t;
    begin
        dummy_insertion_bit   := to_std_logic(bitwise_contains(flags, DUMMY_INSERTION));
        dual_exposure_bit     := to_std_logic(bitwise_contains(flags, DUAL_EXPOSURE));
        external_exposure_bit := to_std_logic(bitwise_contains(flags, EXTERNAL_EXPOSURE));

        encoded_flags := "00000" & dummy_insertion_bit & dual_exposure_bit & external_exposure_bit;
        return l8_instructions(encoded_flags, addr_misc);
    end function misc_instructions;

    pure function n_channels_instructions(n_channels : integer) return logic16_vector_t is
        -- For now this function leaves all channels enabled
        constant addr_n_channels : integer := 72;
    begin
        case n_channels is
        when 16 => return i8_instructions(0, addr_n_channels);
        when  8 => return i8_instructions(1, addr_n_channels);
        when  4 => return i8_instructions(2, addr_n_channels);
        when  2 => return i8_instructions(3, addr_n_channels);
        when others =>
            report "Invalid number of channels detected in n_channels_instructions()" severity failure;
            return i8_instructions(0, addr_n_channels);
        end case;
    end function n_channels_instructions;

    pure function calibration_instructions(config : vnir_config_t) return logic16_vector_t is
    begin
        return i8_instructions(0, 0);  -- TODO: do calibration
    end;

    pure function bit_mode_instructions(pixel_bits : integer) return logic16_vector_t is
        constant addr_bit_mode : integer := 111;
        constant addr_adc_res : integer := 112;
        variable bit_mode : integer;
        variable adc_res : integer;
    begin
        if pixel_bits /= 10 and pixel_bits /= 12 then
            report "Invalid bit mode detected in bit_mode_instructions()" severity failure;
        end if;

        if pixel_bits = 10 then bit_mode := 1; else bit_mode := 0; end if;
        if pixel_bits = 10 then adc_res := 0; else adc_res := 2; end if;

        return i8_instructions(bit_mode, addr_bit_mode)
                & i8_instructions(adc_res, addr_adc_res);
    end function bit_mode_instructions;

    pure function pll_instructions(sensor_clock_MHz : integer; pixel_bits : integer) return logic16_vector_t is
        constant addr_pll_range : integer := 116;
        constant addr_pll_load : integer := 117;
        constant addr_pll_in_freq : integer := 114;
        variable pll_load : integer;
        variable pll_div : integer;
        variable pll_range : integer;
        variable pll_out_freq : integer;
        variable pll_in_freq : integer;
    begin
        if pixel_bits /= 10 and pixel_bits /= 12 then
            report "Invalid bit mode detected in pll_instructions()" severity failure;
        end if;

        if pixel_bits = 10 then pll_load := 8; else pll_load := 4; end if;
        if pixel_bits = 10 then pll_div := 9; else pll_div := 11; end if;
        
        case sensor_clock_MHz is
        when 48 downto 31 => pll_range := 1; pll_out_freq := 5; pll_in_freq := 0;
        when 30 downto 21 => pll_range := 0; pll_out_freq := 1; pll_in_freq := 0;
        when 20 downto 16 => pll_range := 1; pll_out_freq := 1; pll_in_freq := 1;
        when 15 downto 11 => pll_range := 0; pll_out_freq := 2; pll_in_freq := 1;
        when 10 downto  8 => pll_range := 1; pll_out_freq := 2; pll_in_freq := 3;
        when  7 downto  5 => pll_range := 0; pll_out_freq := 0; pll_in_freq := 3;
        when others =>
            report "Invalid sensor clock speed in pll_instructions()" severity failure;
            pll_range := 1; pll_out_freq := 5; pll_in_freq := 0;
        end case;

        return l8_instructions(to_logic1(pll_range) & to_logic3(pll_out_freq) & to_logic4(pll_div), addr_pll_range)
                & i8_instructions(pll_load, addr_pll_load)
                & i8_instructions(pll_in_freq, addr_pll_in_freq);
    end function pll_instructions;

    pure function undocumented_instructions return logic16_vector_t is
        -- There are a lot of instructions specified on page 43 of the manual that have recommended
        -- initial values, but are otherwise undocumented. They are initialized here.
    begin
        return i8_instructions(0, 77)
             & i8_instructions(4, 84)
             & i8_instructions(1, 85)
             & i8_instructions(14, 86)
             & i8_instructions(12, 87)
             & i8_instructions(64, 88)
             & i8_instructions(64, 91)
             & i8_instructions(101, 94)
             & i8_instructions(106, 95)
             & i8_instructions(98, 123);
    end function undocumented_instructions;

    pure function all_instructions (config : vnir_config_t) return logic16_vector_t is
        -- TODO: check out i_lvds
    begin
        return window_instructions(config)
             & flip_instructions(config.flip)
             & misc_instructions(EXTERNAL_EXPOSURE or DUMMY_INSERTION)
             & n_channels_instructions(vnir_lvds_n_channels)
             & calibration_instructions(config)
             & bit_mode_instructions(vnir_pixel_bits)
             & pll_instructions(48, vnir_pixel_bits)  -- TODO: set this properly
             & undocumented_instructions;
    end function all_instructions;

end package body vnir_sensor_config_pkg;
