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
begin
    
    -- TODO: this needs a proper implementation,
    --       probably using a dual-clock FIFO
    o <= i;
    
end architecture rtl;
