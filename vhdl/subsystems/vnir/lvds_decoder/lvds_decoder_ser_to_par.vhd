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

entity lvds_decoder_ser_to_par is
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
end entity lvds_decoder_ser_to_par;

architecture rtl of lvds_decoder_ser_to_par is
    component lvds_rx_10_17 is
    port (
        rx_channel_data_align   : in std_logic_vector (17-1 downto 0);
        rx_in                   : in std_logic_vector (17-1 downto 0);
        rx_inclock              : in std_logic;
        rx_out                  : out std_logic_vector (10*17-1 downto 0);
        rx_outclock             : out std_logic
    );
    end component lvds_rx_10_17;
begin
    instantiate_17_10 : if n_channels = 17 and bit_width = 10 generate
        lvds_rx : lvds_rx_10_17 port map (
            rx_channel_data_align => rx_channel_data_align,
            rx_in => rx_in,
            rx_inclock => rx_inclock,
            rx_out => rx_out,
            rx_outclock => rx_outclock
        );
    end generate;
end architecture rtl;
