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
use ieee.math_real.all;

library altera_mf;
use altera_mf.all;

entity lvds_decoder_fifo is
generic (
    breadth     : integer;
    depth       : integer := 8;
    show_ahead  : boolean := false
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
end entity lvds_decoder_fifo;

architecture rtl of lvds_decoder_fifo is
    component dcfifo
	generic (
        intended_device_family  : string;
        lpm_numwords            : natural;
        lpm_showahead		    : string;
        lpm_type                : string;
        lpm_width               : natural;
        lpm_widthu              : natural;
        overflow_checking       : string;
        rdsync_delaypipe        : natural;
        read_aclr_synch		    : string;
        underflow_checking      : string;
        use_eab	                : string;
        write_aclr_synch        : string;
        wrsync_delaypipe        : natural
	);
	port (
        aclr    : in std_logic;
        data    : in std_logic_vector (breadth-1 downto 0);
        rdclk   : in std_logic;
        rdreq   : in std_logic;
        wrclk   : in std_logic;
        wrreq   : in std_logic;
        q       : out std_logic_vector (breadth-1 downto 0);
        rdempty : out std_logic;
        wrfull  : out std_logic 
	);
    end component dcfifo;
    
    pure function to_on_off(b : boolean) return string is
    begin
        if b then return "ON"; else return "OFF"; end if;
    end function to_on_off;

    constant lpm_showahead : string := to_on_off(show_ahead);
begin
    dcfifo_component : dcfifo generic map (
        intended_device_family => "Cyclone V",
        lpm_numwords => depth,
        lpm_showahead => lpm_showahead,
        lpm_type => "dcfifo",
        lpm_width => breadth,
        lpm_widthu => integer(ceil(log2(real(depth)))),
        overflow_checking => "ON",
        rdsync_delaypipe => 5,
        read_aclr_synch => "ON",
        underflow_checking => "ON",
        use_eab => "ON",
        write_aclr_synch => "OFF",
        wrsync_delaypipe => 5
    ) port map (
        aclr => aclr,
        data => data,
        rdclk => rdclk,
		rdreq => rdreq,
		wrclk => wrclk,
        wrreq => wrreq,
        q => q,
        rdempty => rdempty,
        wrfull => wrfull
    );
end architecture rtl;
