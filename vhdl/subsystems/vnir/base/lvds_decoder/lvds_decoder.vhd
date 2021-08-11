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

use work.vnir_base.all;
use work.lvds_decoder_pkg.all;

entity lvds_decoder is
generic (
    FRAGMENT_WIDTH      : integer;
    PIXEL_BITS          : integer
);
port (
    clock               : in std_logic;
    reset_n             : in std_logic;

    start_align         : in std_logic;
    align_done          : out std_logic;
    
    lvds_data           : in std_logic_vector(FRAGMENT_WIDTH-1 downto 0);
    lvds_control        : in std_logic;
    lvds_clock          : in std_logic;
    
    fragment            : out pixel_vector_t(FRAGMENT_WIDTH-1 downto 0)(PIXEL_BITS-1 downto 0);
    fragment_control    : out control_t;
    fragment_available  : out std_logic;

    status              : out status_t
);
end entity lvds_decoder;

architecture rtl of lvds_decoder is
    component clock_bridge is
    port (
        reset_n : in std_logic;
        i_clock : in std_logic;
        i       : in std_logic;
        o_clock : in std_logic;
        o       : out std_logic
    );
    end component clock_bridge;

    component lvds_decoder_in is
    generic (
        FRAGMENT_WIDTH  : integer;
        PIXEL_BITS      : integer;
        FIFO_BITS       : integer
    );
    port (
        clock           : out std_logic;
        reset_n         : in std_logic;
        lvds_data       : in std_logic_vector;
        lvds_control    : in std_logic;
        lvds_clock      : in std_logic;
        start_align     : in std_logic;
        to_fifo         : out std_logic_vector
    );
    end component lvds_decoder_in;

    component lvds_decoder_fifo is
    generic (
        BREADTH : integer
    );
    port (
        aclr		: in std_logic;
        data		: in std_logic_vector;
        rdclk		: in std_logic;
        rdreq		: in std_logic;
        wrclk		: in std_logic;
        wrreq		: in std_logic;
        q		    : out std_logic_vector;
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
    generic (
        FRAGMENT_WIDTH  : integer;
        PIXEL_BITS      : integer
    );
    port (
        clock               : in std_logic;
        reset_n             : in std_logic;
        data_in_available   : in std_logic;
        from_fifo           : in std_logic_vector;
        align_done          : out std_logic;
        fragment            : out pixel_vector_t;
        fragment_control    : out control_t;
        fragment_available  : out std_logic
    );
    end component lvds_decoder_out;

    constant FRAGMENT_BITS : integer := FRAGMENT_WIDTH * PIXEL_BITS;
    constant FIFO_BITS : integer := FRAGMENT_BITS
                                        + PIXEL_BITS  -- control
                                        + 1; -- is_aligned

    signal inclock : std_logic;
    signal outclock : std_logic;
    signal start_align_inclock : std_logic;
    signal start_align_outclock : std_logic;
    signal to_fifo : std_logic_vector(FIFO_BITS-1 downto 0);
    signal from_fifo : std_logic_vector(FIFO_BITS-1 downto 0);
    signal fifo_did_read : std_logic;
    signal rdempty : std_logic;
    signal wrfull : std_logic;
begin

    start_align_outclock <= start_align;
    start_align_bridge : clock_bridge port map (
        reset_n => reset_n,
        i_clock => outclock,
        i => start_align_outclock,
        o_clock => inclock,
        o => start_align_inclock
    );

    decoder_in_component : lvds_decoder_in generic map (
        FRAGMENT_WIDTH => FRAGMENT_WIDTH,
        PIXEL_BITS => PIXEL_BITS,
        FIFO_BITS => FIFO_BITS
    ) port map (
        clock => inclock,
        reset_n => reset_n,  -- TODO: how should a reset cross a clock boundary?
        lvds_data => lvds_data,
        lvds_control => lvds_control,
        lvds_clock => lvds_clock,
        start_align => start_align_inclock,
        to_fifo => to_fifo
    );

    fifo_component : lvds_decoder_fifo generic map (
        BREADTH => FIFO_BITS
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
    decoder_out_component : lvds_decoder_out generic map (
        FRAGMENT_WIDTH => FRAGMENT_WIDTH,
        PIXEL_BITS => PIXEL_BITS
    ) port map (
        clock => outclock,
        reset_n => reset_n,
        data_in_available => fifo_did_read,
        from_fifo => from_fifo,
        align_done => align_done,
        fragment => fragment,
        fragment_control => fragment_control,
        fragment_available => fragment_available
    );

end architecture rtl;
