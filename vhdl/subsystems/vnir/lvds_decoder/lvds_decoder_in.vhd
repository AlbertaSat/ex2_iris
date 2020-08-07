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

use work.vnir_common.all;
use work.lvds_decoder_pkg.all;

entity lvds_decoder_in is
port (
    clock       : out std_logic;
    reset_n     : in std_logic;
    lvds        : in lvds_t;
    start_align : in std_logic;
    to_fifo     : out fifo_data_t
);
end entity lvds_decoder_in;


architecture rtl of lvds_decoder_in is
    component lvds_decoder_ser_to_par is
    generic (
        N_CHANNELS : integer;
        BIT_WIDTH  : integer
    );
    port (
        rx_channel_data_align   : in std_logic_vector(N_CHANNELS-1 downto 0);
        rx_in                   : in std_logic_vector(N_CHANNELS-1 downto 0);
        rx_inclock              : in std_logic;
        rx_out                  : out std_logic_vector(BIT_WIDTH*N_CHANNELS-1 downto 0);
        rx_outclock             : out std_logic
    );
    end component lvds_decoder_ser_to_par;

    subtype lpixel_t is std_logic_vector(PIXEL_BITS-1 downto 0);
    subtype lcontrol_t is std_logic_vector(FRAGMENT_BITS-1 downto 0);

    constant LCONTROL_TARGET : lpixel_t := (PIXEL_BITS-9-1 => '1', others => '0');
    
    signal data_align : std_logic;
    signal decoder_outclock : std_logic;

    signal fragment  : fragment_t;
    signal control   : control_t;
    signal lfragment : lcontrol_t;
    signal lcontrol  : lpixel_t;
begin
    ser_to_par : lvds_decoder_ser_to_par generic map (
        N_CHANNELS => FRAGMENT_WIDTH + 1,
        BIT_WIDTH => PIXEL_BITS
    ) port map (
        rx_channel_data_align => (FRAGMENT_WIDTH downto 0 => data_align),
        rx_in(FRAGMENT_WIDTH downto 1) => lvds.data,
        rx_in(0) => lvds.control,
        rx_inclock => lvds.clock,
        rx_out(FRAGMENT_BITS + PIXEL_BITS - 1 downto PIXEL_BITS) => lfragment,
        rx_out(PIXEL_BITS - 1 downto 0) => lcontrol,
        rx_outclock => decoder_outclock
    );
    clock <= decoder_outclock;

    fragment <= bitreverse(unpack_to_fragment(lfragment));
    control <= to_control(bitreverse(lcontrol));

    fsm : process (decoder_outclock)
        type state_t is (RESET, IDLE, READOUT, ALIGN_HIGH, ALIGN_LOW, ALIGN_WAIT);
        variable state : state_t;
        variable offset : integer;
        variable control_msb : pixel_t;
    begin
        if rising_edge(decoder_outclock) then
            to_fifo.is_aligned <= '0';
            data_align <= '0';
            if reset_n = '0' then
                state := RESET;
            end if;

            case state is
            when RESET =>
                state := IDLE;
            when IDLE =>
                if start_align = '1' then
                    offset := calc_align_offset(lcontrol, LCONTROL_TARGET);
                    if offset = 0 then state := READOUT; else state := ALIGN_HIGH; end if;
                end if;
            when READOUT =>
                if start_align = '1' then
                    offset := calc_align_offset(lcontrol, LCONTROL_TARGET);
                    if offset = 0 then state := READOUT; else state := ALIGN_HIGH; end if;
                else
                    to_fifo.is_aligned <= '1';
                    to_fifo.fragment <= fragment;
                    to_fifo.control  <= control;
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
                if lcontrol = LCONTROL_TARGET then  -- TODO: might fail due to unset output
                    state := READOUT;
                end if;
            end case;
        
        end if;

    end process fsm;

end architecture rtl;
