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


entity divider is
port (
    clock       : in std_logic;
    reset_n     : in std_logic;
    numerator   : in integer;
    denominator : in integer;
    quotient    : out integer;
    start       : in std_logic;
    done        : out std_logic
);
end entity divider;


architecture rtl of divider is
    
    constant CLOCKS_TO_COMPUTE : integer := 5;

    signal numerator_reg : integer;
    signal denominator_reg : integer;
    signal quotient_reg : integer;
	 
    attribute altera_attribute : string;
    attribute altera_attribute of rtl : architecture is "-name SDC_STATEMENT ""set_multicycle_path -from [get_registers *divider:*_reg*] -to [get_registers *divider:*quotient*] -setup -start 4; set_multicycle_path -from [get_registers *divider:*_reg*] -to [get_registers *divider:*quotient*] -hold  -start 4""";

begin

    quotient_reg <= numerator_reg / denominator_reg;
    
    process
        type state_t is (RESET, IDLE, CALCULATING);
        variable state : state_t;

        variable t : integer;
    begin
        wait until rising_edge(clock);

        done <= '0';

        if reset_n = '0' then
            state := RESET;
        end if;

        case state is
        when RESET => state := IDLE;
        when IDLE =>
            if start = '1' then
                t := 0;
                numerator_reg <= numerator;
                denominator_reg <= denominator;
                state := CALCULATING;
            end if;
        when CALCULATING =>
            if t = CLOCKS_TO_COMPUTE then
                state := IDLE;
                quotient <= quotient_reg;
                done <= '1';
            end if;
            t := t + 1;
        end case;
    
    end process;
    
end architecture rtl;
