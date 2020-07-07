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

entity lvds_decoder is
port (
    clock          : in std_logic;
    reset_n        : in std_logic;
    start_align    : in std_logic;
    align_done     : out std_logic;
    lvds_in        : in vnir_lvds_t;
    parallel_out   : out vnir_parallel_lvds_t;
    data_available : out std_logic
);
end entity lvds_decoder;

architecture rtl of lvds_decoder is
    component cmd_cross_clock is
    port (
        reset_n : in std_logic;
        i_clock : in std_logic;
        i       : in std_logic;
        o_clock : in std_logic;
        o       : out std_logic
    );
    end component cmd_cross_clock;

    component lvds_decoder_in is
    port (
        clock       : out std_logic;
        reset_n     : in std_logic;
        lvds_in     : in vnir_lvds_t;
        start_align : in std_logic;
        to_fifo     : out fifo_data_t
    );
    end component lvds_decoder_in;

    component lvds_decoder_fifo is
    generic (
        breadth : integer
    );
    port (
        aclr		: in std_logic;
        data		: in std_logic_vector(breadth-1 downto 0);
        rdclk		: in std_logic;
        rdreq		: in std_logic;
        wrclk		: in std_logic;
        wrreq		: in std_logic;
        q		    : out std_logic_vector(breadth-1 downto 0);
        rdempty		: out std_logic;
        wrfull		: out std_logic 
    );
    end component lvds_decoder_fifo;

    component single_delay is
    port (
        clock   : in std_logic;
        reset_n : in std_logic;
        i       : in std_logic;
        o       : out std_logic
    );
    end component single_delay;

    component lvds_decoder_out is
    port (
        clock               : in std_logic;
        reset_n             : in std_logic;
        data_in_available   : in std_logic;
        from_fifo           : in fifo_data_t;
        align_done          : out std_logic;
        data_out_available  : out std_logic;
        parallel_out        : out vnir_parallel_lvds_t
    );
    end component lvds_decoder_out;

    signal inclock : std_logic;
    signal outclock : std_logic;
    signal start_align_inclock : std_logic;
    signal start_align_outclock : std_logic;
    signal to_fifo : fifo_data_t;
    signal from_fifo : fifo_data_t;
    signal fifo_did_read : std_logic;
    signal rdempty : std_logic;
    signal wrfull : std_logic;
begin

    start_align_outclock <= start_align;
    start_align_bridge : cmd_cross_clock port map (
        reset_n => reset_n,
        i_clock => outclock,
        i => start_align_outclock,
        o_clock => inclock,
        o => start_align_inclock
    );

    decoder_in_component : lvds_decoder_in port map (
        clock => inclock,
        reset_n => reset_n,  -- TODO: how should a reset cross a clock boundary?
        lvds_in => lvds_in,
        start_align => start_align_inclock,
        to_fifo => to_fifo
    );

    fifo_component : lvds_decoder_fifo generic map (
        breadth => n_fifo_channels * vnir_pixel_bits
    ) port map (
        aclr => not reset_n,
        data => to_fifo,
        rdclk => outclock,
        rdreq => not rdempty,
        wrclk => inclock,
        wrreq => not wrfull,
        q => from_fifo,
        rdempty => rdempty,
        wrfull => wrfull  -- TODO: if this is ever high, throw an exception or something
    );

    set_did_read : single_delay port map (
        clock => outclock,
        reset_n => reset_n,
        i => not rdempty,
        o => fifo_did_read
    );

    outclock <= clock;
    decoder_out_component : lvds_decoder_out port map (
        clock => outclock,
        reset_n => reset_n,
        data_in_available => fifo_did_read,
        from_fifo => from_fifo,
        align_done => align_done,
        data_out_available => data_available,
        parallel_out => parallel_out
    );

end architecture rtl;
