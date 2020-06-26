library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.vnir_types.all;


entity collate_rows is
port (
    clock           : in std_logic;
    reset_n         : in std_logic;
    lvds            : in vnir_lvds_parallel_t;
    lvds_available  : in std_logic;
    row_1           : out vnir_row_t;
    row_2           : out vnir_row_t;
    row_3           : out vnir_row_t;
    rows_available  : out std_logic
);
end;


architecture rtl of collate_rows is
    constant serial_pixels : integer := 512;  -- 2048 / 4

    constant sum_pixel_bits : integer := 19;
    subtype sum_pixel_t is unsigned(0 to sum_pixel_bits-1);
    type sum_row_t is array(0 to vnir_row_width-1) of sum_pixel_t;  
    type state_t is (IDLE, DECODING_1, DECODING_2, DECODING_3);
    signal state : state_t;

    type counters_t is record
        pixel : integer;
        row 	: integer; 
    end record counters_t;

    procedure reset (
        variable counters : inout counters_t;
        variable sum_row : inout sum_row_t
    ) is
    begin
        counters.pixel := 0;
        counters.row := 0;
        sum_row := (others => (others => '0'));
    end procedure reset;
   
    procedure increment_sum (
        signal lvds : in vnir_lvds_parallel_t;
        variable sum_row : inout sum_row_t;
        variable counters : in counters_t
    ) is
    begin
        sum_row(counters.pixel + serial_pixels * 0) := sum_row(counters.pixel + serial_pixels * 0) + lvds(0);
        sum_row(counters.pixel + serial_pixels * 1) := sum_row(counters.pixel + serial_pixels * 1) + lvds(1);
        sum_row(counters.pixel + serial_pixels * 2) := sum_row(counters.pixel + serial_pixels * 2) + lvds(2);
        sum_row(counters.pixel + serial_pixels * 3) := sum_row(counters.pixel + serial_pixels * 3) + lvds(3);
    end procedure increment_sum;

    procedure increment_counters (
        variable counters : inout counters_t;
        variable max_rows : in integer
    ) is
    begin
        counters.pixel := counters.pixel + 1;
        if (counters.pixel = serial_pixels) then
            counters.pixel := 0;
            counters.row := counters.row + 1;
        end if;
        if (counters.row = max_rows) then
            counters.row := 0;
        end if;
    end procedure increment_counters;

    procedure sum_to_average (
        variable sum_row : in sum_row_t;
        variable max_rows : in integer;
        signal row : out vnir_row_t
    ) is
        variable t : sum_pixel_t;
    begin
        for i in 0 to 2048-1 loop
            t := sum_row(i) / max_rows;
            row(i) <= t(7 to 19-1);
        end loop;
    end procedure sum_to_average;

begin

    main_process : process (clock)
        variable counters : counters_t;
        variable sum_row : sum_row_t;
        variable max_rows : integer := 10; -- TODO: set from config
    begin
        if rising_edge(clock) then
            rows_available <= '0';
            if (reset_n = '0') then
                state <= IDLE;
            elsif (lvds_available = '1') then
                case state is
                when IDLE =>
                    state <= DECODING_1;
                    reset(counters, sum_row);
                    increment_sum(lvds, sum_row, counters);
                    increment_counters(counters, max_rows);
                when DECODING_1 =>
                    increment_sum(lvds, sum_row, counters);
                    increment_counters(counters, max_rows);
                    if (counters.pixel = 0 and counters.row = 0) then
                        sum_to_average(sum_row, max_rows, row_1);
                        reset(counters, sum_row);
                        state <= DECODING_2;
                    end if;
                when DECODING_2 =>
                    increment_sum(lvds, sum_row, counters);
                    increment_counters(counters, max_rows);
                    if (counters.pixel = 0 and counters.row = 0) then
                        sum_to_average(sum_row, max_rows, row_2);
                        reset(counters, sum_row);
                        state <= DECODING_3;
                    end if;
                when DECODING_3 =>
                    increment_sum(lvds, sum_row, counters);
                    increment_counters(counters, max_rows);
                    if (counters.pixel = 0 and counters.row = 0) then
                        sum_to_average(sum_row, max_rows, row_3);
                        reset(counters, sum_row);
                        state <= IDLE;
                        rows_available <= '1';
                    end if;
                end case;
            end if;
        end if;
    end process;
end architecture rtl;
