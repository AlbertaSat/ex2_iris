library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.vnir_types.all;
use work.logic_types.all;


package sensor_configurer_pkg is
    constant num_windows : integer := 3;

    type sensor_configurer_config_t is record
        flip        : vnir_flip_t;
        calibration : vnir_calibration_t;
        windows     : vnir_window_vector_t(num_windows-1 downto 0);
    end record sensor_configurer_config_t;

    pure function l8_instructions(l8 : logic8_t; addr : integer) return logic16_vector_t;
    pure function i8_instructions(i8 : integer; addr : integer) return logic16_vector_t;
    pure function l16_instructions(l16 : logic16_t; addr : integer) return logic16_vector_t;
    pure function i16_instructions(i16 : integer; addr : integer) return logic16_vector_t;
    
    pure function window_instructions(window : vnir_window_t; index : integer) return logic16_vector_t;
    pure function window_instructions(config : sensor_configurer_config_t) return logic16_vector_t;
    pure function flip_instructions(flip : vnir_flip_t) return logic16_vector_t;
    pure function misc_instructions(flags : std_logic_vector) return logic16_vector_t;
    pure function n_channels_instructions(n_channels : integer) return logic16_vector_t;
    pure function calibration_instructions(calibration : vnir_calibration_t) return logic16_vector_t;
    pure function bit_mode_instructions(pixel_bits : integer) return logic16_vector_t;
    pure function pll_instructions(sensor_clock_MHz : integer; pixel_bits : integer) return logic16_vector_t;
    pure function undocumented_instructions return logic16_vector_t;
    pure function all_instructions (config : sensor_configurer_config_t) return logic16_vector_t;

end package sensor_configurer_pkg;

package body sensor_configurer_pkg is

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

    pure function window_instructions(config : sensor_configurer_config_t) return logic16_vector_t is
        constant addr_total_rows : integer := 1;
    begin
        assert config.windows'length = 3;
        return i16_instructions(total_rows(config.windows), addr_total_rows)
             & window_instructions(config.windows(0), 0)
             & window_instructions(config.windows(1), 1)
             & window_instructions(config.windows(2), 2);
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

    pure function calibration_instructions(calibration : vnir_calibration_t) return logic16_vector_t is
        constant addr_adc_gain : integer := 103;
        constant addr_v_ramp1 : integer := 98;
        constant addr_v_ramp2 : integer := 99;
        constant addr_offset : integer := 100;
    begin
        return i8_instructions(calibration.adc_gain, addr_adc_gain)
             & i8_instructions(calibration.v_ramp1, addr_v_ramp1)
             & i8_instructions(calibration.v_ramp2, addr_v_ramp2)
             & i16_instructions(calibration.offset, addr_offset);
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
             & i8_instructions(1, 102)
             & i8_instructions(1, 118)
             & i8_instructions(98, 123);
    end function undocumented_instructions;

    pure function all_instructions (config : sensor_configurer_config_t) return logic16_vector_t is
        -- TODO: check out i_lvds
    begin
        return window_instructions(config)
             & flip_instructions(config.flip)
             & misc_instructions(EXTERNAL_EXPOSURE or DUMMY_INSERTION)
             & n_channels_instructions(vnir_lvds_n_channels)
             & calibration_instructions(config.calibration)
             & bit_mode_instructions(vnir_pixel_bits)
             & pll_instructions(48, vnir_pixel_bits)  -- TODO: set this properly
             & undocumented_instructions;
    end function all_instructions;

end package body sensor_configurer_pkg;
