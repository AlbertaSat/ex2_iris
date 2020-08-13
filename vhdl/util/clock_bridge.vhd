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

library altera_mf;
use altera_mf.all;

entity clock_bridge is
port (
    reset_n   : in std_logic;
    i_clock   : in std_logic;
    i         : in std_logic;
    o_clock   : in std_logic;
    o         : out std_logic;
    o_reset_n : out std_logic
);
end entity clock_bridge;

architecture rtl of clock_bridge is
    component dcfifo
    generic (
        intended_device_family  : string    := "Cyclone V";
        lpm_numwords            : natural   := 4;
        lpm_showahead           : string    := "ON";
        lpm_type                : string    := "dcfifo";
        lpm_width               : natural   := 2;
        lpm_widthu              : natural   := 2;
        overflow_checking       : string    := "ON";
        rdsync_delaypipe        : natural   := 4;
        read_aclr_synch         : string    := "OFF";
        underflow_checking      : string    := "ON";
        use_eab                 : string    := "ON";
        write_aclr_synch        : string    := "OFF";
        wrsync_delaypipe        : natural   := 4
    );
    port (
        aclr    : in std_logic;
        data    : in std_logic_vector;
        rdclk   : in std_logic;
        rdreq   : in std_logic;
        wrclk   : in std_logic;
        wrreq   : in std_logic;
        q       : out std_logic_vector;
        rdempty : out std_logic;
        wrfull  : out std_logic 
    );
    end component;

    signal data : std_logic_vector(1 downto 0);
    signal q : std_logic_vector(1 downto 0);
    signal rdempty : std_logic;
    signal wrfull : std_logic;
begin

    fifo : dcfifo port map (
		aclr => not reset_n,
        data => data,
		rdclk => o_clock,
		rdreq => not rdempty,
		wrclk => i_clock,
		wrreq => i and not wrfull,
		q => q,
		rdempty => rdempty,
		wrfull => wrfull  -- TODO: if this is ever high, raise an error or something
	);
    
    data(0) <= i;
    data(1) <= reset_n;

    o <= q(0) and not rdempty;
    o_reset_n <= q(1) or rdempty;

end architecture rtl;
