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

    signal reset : std_logic;
    signal data : std_logic_vector(0 downto 0);
    signal rdack : std_logic;
    signal q : std_logic_vector(0 downto 0);
    signal rdempty : std_logic;
begin
    
    reset <= not reset_n;
    data(0) <= i;
    o <= q(0) and not rdempty;
    rdack <= not rdempty;

    cmd_fifo : fifo_1 port map (
        aclr => reset,
        data => data,
        rdclk => o_clock,
        rdreq => rdack,
        wrclk => i_clock,
        wrreq => i,
        q => q,
        rdempty => rdempty,
        wrfull => open
    );
    
end architecture rtl;
