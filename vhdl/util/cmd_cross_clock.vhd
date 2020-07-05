library ieee;
use ieee.std_logic_1164.all;

entity cmd_cross_clock is
port (
    reset_n : in std_logic;
    i_clock : in std_logic;
    i       : in std_logic;
    o_clock : in std_logic;
    o       : out std_logic
);
end entity cmd_cross_clock;

architecture rtl of cmd_cross_clock is
    component fifo_1
    port (
        aclr		: in std_logic;
        data		: in std_logic_vector(0 downto 0);
        rdclk		: in std_logic;
        rdreq		: in std_logic;
        wrclk		: in std_logic;
        wrreq		: in std_logic;
        q		    : out std_logic_vector(0 downto 0);
        rdempty		: out std_logic;
        wrfull		: out std_logic 
    );
    end component;

    signal q : std_logic;
    signal rdempty : std_logic;
    signal wrfull : std_logic;
begin
    
    o <= q and not rdempty;

    cmd_fifo : fifo_1 port map (
        aclr => not reset_n,
        data(0) => i,
        rdclk => o_clock,
        rdreq => not rdempty,
        wrclk => i_clock,
        wrreq => i and not wrfull,
        q(0) => q,
        rdempty => rdempty,
        wrfull => wrfull  -- TODO: if this is ever high, raise an error or something
    );
    
end architecture rtl;
