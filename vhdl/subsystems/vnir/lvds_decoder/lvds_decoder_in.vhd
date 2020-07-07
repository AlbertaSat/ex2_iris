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
use work.lvds_decoder_pkg.all;

entity lvds_decoder_in is
port (
    clock       : out std_logic;
    reset_n     : in std_logic;
    lvds_in     : in vnir_lvds_t;
    start_align : in std_logic;
    to_fifo     : out fifo_data_t
);
end entity lvds_decoder_in;


architecture rtl of lvds_decoder_in is
    component lvds_decoder_ser_to_par is
    generic (
        n_channels : integer;
        bit_width  : integer
    );
    port (
        rx_channel_data_align   : in std_logic_vector (n_channels-1 downto 0);
        rx_in                   : in std_logic_vector (n_channels-1 downto 0);
        rx_inclock              : in std_logic;
        rx_out                  : out std_logic_vector (bit_width*n_channels-1 downto 0);
        rx_outclock             : out std_logic
    );
    end component lvds_decoder_ser_to_par;
    
    pure function calc_align_offset(control : vnir_pixel_t; control_target : vnir_pixel_t)
                                    return integer is
    begin
        for i in 0 to vnir_pixel_bits-1 loop
            if rotate_right(control, i) = control_target then
                return i;
            end if;
        end loop;

        return 0;  -- TODO: trigger some kind of error if we get here
    end function calc_align_offset;

    constant n_decoder_channels : integer := vnir_lvds_data_width + 1; -- Add control
    constant control_target : vnir_pixel_t := (vnir_pixel_bits-10 => '1', others => '0');
    signal data_align : std_logic;
    signal decoder_out : std_logic_vector(n_decoder_channels*vnir_pixel_bits-1 downto 0);
    signal decoder_outclock : std_logic;
begin
    ser_to_par : lvds_decoder_ser_to_par generic map (
        n_channels => n_decoder_channels,
        bit_width => vnir_pixel_bits
    ) port map (
        rx_channel_data_align => (n_decoder_channels-1 downto 0 => data_align),
        rx_in(n_decoder_channels-1 downto 1) => lvds_in.data,
        rx_in(0) => lvds_in.control,
        rx_inclock => lvds_in.clock,
        rx_out => decoder_out,
        rx_outclock => decoder_outclock
    );
    clock <= decoder_outclock;

    fsm : process (decoder_outclock)
        type state_t is (RESET, IDLE, READOUT, ALIGN_HIGH, ALIGN_LOW, ALIGN_WAIT);
        variable state : state_t;
        variable offset : integer;
        variable control : vnir_pixel_t;
    begin
        if rising_edge(decoder_outclock) then
            to_fifo <= (others => '0');
            data_align <= '0';
            if reset_n = '0' then
                state := RESET;
            end if;

            control := unsigned(decoder_out(vnir_pixel_bits-1 downto 0));

            case state is
            when RESET =>
                state := IDLE;
            when IDLE =>
                if start_align = '1' then
                    state := ALIGN_HIGH;
                    offset := calc_align_offset(control, control_target);
                end if;
            when READOUT =>
                if start_align = '1' then
                    state := ALIGN_HIGH;
                    offset := calc_align_offset(control, control_target);
                else
                    to_fifo <= (others => '1');
                    to_fifo(vnir_pixel_bits*n_fifo_channels-1 downto vnir_pixel_bits) <= decoder_out;
                end if;
            when ALIGN_HIGH =>
                state := ALIGN_LOW;
                data_align <= '1';
            when ALIGN_LOW =>
                offset := offset - 1;
                if offset = 0 then
                    state := ALIGN_WAIT;
                else
                    state := ALIGN_HIGH;
                end if;
            when ALIGN_WAIT =>
                if control = control_target then  -- TODO: might fail due to unset output
                    state := READOUT;
                end if;
            end case;
        
        end if;

    end process fsm;

end architecture rtl;