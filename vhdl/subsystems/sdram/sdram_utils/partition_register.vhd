library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.spi_types.all;
use work.avalonmm_types.all;
use work.vnir_types.all;
use work.swir_types.all;
use work.sdram_types.all;
use work.fpga_types.all;

entity partition_register is
    port(
        --Control signals
        clk, reset_n : in std_logic;

        --Enable signal for writing to both bounds and filled bounds
        bounds_write, filled_add, filled_subtract : in std_logic;

        --Values to write
        base, bounds, add_sub_length : in sdram_address;

        --Partition read from the register
        part_out : out partition_t;

        --Unsigneds representing the new image
        img_start, img_end : out sdram_address;

        --Error signals
        full, bad_mpu_check : out std_logic
    );
end entity partition_register;

architecture rtl of partition_register is
    type state_t is (init, idle, add_address, sub_address);
    signal state, next_state : state_t;

    --This signal allows the register to see what's in the part_out signal
    signal buffer_part : partition_t;

    --These signals are combinational, and can be written to at any time
    signal buffer_base, buffer_bounds : sdram_address;
    signal buffer_fill_base, buffer_fill_bounds : sdram_address;

    --A flag saying the partition cannot be added to
    signal no_add : std_logic;

    --Checks if the image will overflow the position, returns 1 if it does
    function check_overflow(partition : partition_t, address_size : sdram_address) return std_logic is
    begin
        if (partition.filled_bounds + address_size > partition.bounds) then
            return '1';
        else
            return '0';
        end if;
    end function check_overflow;
    
    --Checks if the image won't fit in the memory because it is too full, returns 1 if it does
    function check_full(partition : partition_t, address_size : sdram_address, start_address : sdram_address) return std_logic is
    begin
        if (start_address <= partition.fill_base and start_address + address_size >= partition.fill_base) then
            return '1';
        else
            return '0';
        end if;
    end function check_full;
begin
    --Combinitorial process specifying signal assignments
    state_process : process(state, add_sub_length, base, bounds) is
    begin
        case state is
            when init =>
                buffer_base <= base;
                buffer_bounds <= bounds;

            when idle => null;

            --When adding stuff to the memory
            when add_address =>
                --Some complicated conditional checking (yay!)
                if (buffer_part.fill_base < buffer_part.fill_bounds) then
                    if (check_overflow(buffer_part, add_sub_length) = '1') then
                        if (check_full(buffer_part, add_sub_length, buffer_part.base) = '1') then
                            full <= '1';
                            no_add = '1';
                        else
                            buffer_fill_bounds <= buffer_part.base + 1 + add_sub_length;
                            img_start <= buffer_part.base + 1;
                            img_end <= buffer_part.base + 1 + add_sub_length;
                        end if;
                    else
                        --No need to check if it's full, the overflow did that already
                        buffer_fill_bounds <= buffer_part.fill_bounds + 1 + add_sub_length;
                        img_start <= buffer_part.fill_bounds + 1;
                        img_end <= buffer_part.fill_bounds + 1 + add_sub_length;
                    end if;
                else
                    --Just need to check if it's full for this case
                    if (check_full(buffer_part, add_sub_length, buffer_part.fill_bounds) = '1') then
                        full = '1';
                        no_add = '1';
                    else
                        buffer_fill_bounds <= buffer_part.fill_bounds + 1 + add_sub_length;
                        img_start <= buffer_part.fill_bounds + 1;
                        img_end <= buffer_part.fill_bounds + 1 + add_sub_length;
                    end if;
                end if;

            --When taking stuff outta the memory
            when sub_address =>
                if (buffer_part.fill_base + add_sub_length > buffer_part.fill_bounds) then
                    bad_mpu_check <= '1';
                else
                    buffer_fill_base <= buffer_part.fill_base + add_sub_length;
                end if;

                if (no_add = '1') then
                    no_add <= '0';
                    full <= '0';
                end if;
        end case;
    end process;

    --Assigns outputs at the rising edge of the clock
    sig_assign : process (clk, reset_n) is
    begin
        if (reset_n = '0') then
            state <= init;
            buffer_part.base <= (others => '0');
            buffer_part.bounds <= (others => '0');
            buffer_part.fill_base <= (others => '0');
            buffer_part.fill_bounds <= (others => '0');

            part_out.base <= (others => '0');
            part_out.bounds <= (others => '0');
            part_out.fill_base <= (others => '0');
            part_out.fill_bounds <= (others => '0');

        elsif rising_edge(clk) then
            state <= next_state;
            buffer_part.base <= buffer_base;
            buffer_part.bounds <= buffer_bounds;
            buffer_part.fill_base <= buffer_fill_base;
            buffer_part.fill_bounds <= buffer_fill_bounds;

            part_out.base <= buffer_base;
            part_out.bounds <= buffer_bounds;
            part_out.fill_base <= buffer_fill_base;
            part_out.fill_bounds <= buffer_fill_bounds;
        end if;
    end process;

    --Describes when to change the states
    state_change : process (clk, reset_n) is
    begin
        case state is
            when init =>
                if (bounds_write = '1') then
                    next_state <= idle;
                else
                    next_state <= init;
                end if;
            when idle =>
                if (filled_add = '1' and no_add /= '1') then
                    next_state <= add_address;
                elsif (filled_subtract = '1') then
                    next_state <= sub_address;
                else
                    next_state <= idle;
                end if;
            when add_address =>
                --Will only take one clock cycle
                next_state <= idle;
            when sub_address =>
                --This should only take one clock cycle
                next_state <= idle;
        end case;
    end process;
end architecture;