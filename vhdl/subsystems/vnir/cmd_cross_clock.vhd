

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
    process (i, i_clock, o_clock)
        variable trigger : std_logic;
    begin
        if reset_n = '0' then
            trigger = '0';
        else
            if rising_edge(i_clock) and i = '1' then
                trigger := '1';
            end if;
            if rising_edge(o_clock) then
                o <= trigger;
                trigger := '0';
            end if;
        end if;
    end process;
end architecture rtl;
