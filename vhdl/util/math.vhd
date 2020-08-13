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

library lpm;
use lpm.lpm_components.all;

use work.unsigned_types.all;


entity udivide is
generic (
    N_CLOCKS : integer := 4;
    NUMERATOR_BITS : integer := 64;
    DENOMINATOR_BITS : integer := 64
);
port (
    clock       : in std_logic;
    reset_n     : in std_logic;
    numerator   : in u64;
    denominator : in u64;
    quotient    : out u64;
    start       : in std_logic;
    done        : out std_logic
);
end entity udivide;


architecture rtl of udivide is

    component LPM_DIVIDE is 
    generic (
        lpm_drepresentation : string := "UNSIGNED";
        lpm_hint            : string := "MAXIMIZE_SPEED=9,LPM_REMAINDERPOSITIVE=TRUE";
        lpm_nrepresentation : string := "UNSIGNED";
        lpm_pipeline        : natural := N_CLOCKS;
        lpm_type            : string := "LPM_DIVIDE";
        lpm_widthd          : natural := DENOMINATOR_BITS;
        lpm_widthn          : natural := NUMERATOR_BITS
    );
    port (
        clock       : in std_logic;
        aclr        : in std_logic;
        numer       : in std_logic_vector(lpm_widthn-1 downto 0);
        denom       : in std_logic_vector(lpm_widthd-1 downto 0);
        quotient    : out std_logic_vector(lpm_widthn-1 downto 0)
    );
    end component LPM_DIVIDE;

    component n_delay
    generic (
        DELAY_CLOCKS : integer := N_CLOCKS
    );
    port (
        clock   : in std_logic;
        reset_n : in std_logic;
        i       : in std_logic;
        o       : out std_logic
    );
    end component n_delay;
    
    signal quotient_logic : std_logic_vector(NUMERATOR_BITS-1 downto 0);

begin

    compute_quotient : LPM_DIVIDE port map (
        clock => clock,
        aclr => not reset_n,
        numer => std_logic_vector(to_unsigned(numerator, NUMERATOR_BITS)),
        denom => std_logic_vector(to_unsigned(denominator, DENOMINATOR_BITS)),
        quotient => quotient_logic
    );
    quotient <= to_u64(quotient_logic);

    delay : n_delay port map (
        clock => clock,
        reset_n => reset_n,
        i => start,
        o => done
    );

end architecture rtl;
