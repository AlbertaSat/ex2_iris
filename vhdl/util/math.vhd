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


entity idivide is
generic (
    N_CLOCKS : integer := 4;
    NUMERATOR_BITS : integer := 32;
    DENOMINATOR_BITS : integer := 32
);
port (
    clock   : in std_logic;
    reset_n : in std_logic;
    n       : in integer;
    d       : in integer;
    q       : out integer;
    start   : in std_logic;
    done    : out std_logic
);
end entity idivide;


architecture rtl of idivide is

    component LPM_DIVIDE is 
    generic (
        lpm_drepresentation : string := "SIGNED";
        lpm_hint            : string := "MAXIMIZE_SPEED=9,LPM_REMAINDERPOSITIVE=TRUE";
        lpm_nrepresentation : string := "SIGNED";
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
    

    signal q_logic : std_logic_vector(NUMERATOR_BITS-1 downto 0);

begin

    compute_quotient : LPM_DIVIDE port map (
        clock => clock,
        aclr => not reset_n,
        numer => std_logic_vector(to_signed(n, NUMERATOR_BITS)),
        denom => std_logic_vector(to_signed(d, DENOMINATOR_BITS)),
        quotient => q_logic
    );
    q <= to_integer(signed(q_logic));

    delay : n_delay port map (
        clock => clock,
        reset_n => reset_n,
        i => start,
        o => done
    );

end architecture rtl;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library lpm;
use lpm.lpm_components.all;


entity imultiply is
generic (
    N_CLOCKS : integer := 1
);
port (
    clock   : in std_logic;
    reset_n : in std_logic;
    a       : in integer;
    b       : in integer;
    p       : out integer;
    start   : in std_logic;
    done    : out std_logic
);
end entity imultiply;


architecture rtl of imultiply is

    component LPM_MULT is 
    generic (
        lpm_hint            : string := "MAXIMIZE_SPEED=9";
        lpm_pipeline        : natural := N_CLOCKS;
        lpm_representation : string := "SIGNED";
        lpm_type            : string := "LPM_MULT";
        lpm_widtha          : natural := 32;
        lpm_widthb          : natural := 32;
        lpm_widthp          : natural := 32
    );
    port (
        clock       : in std_logic;
        aclr        : in std_logic;
        dataa       : in std_logic_vector(lpm_widtha-1 downto 0);
        datab       : in std_logic_vector(lpm_widthb-1 downto 0);
        result      : out std_logic_vector(lpm_widthp-1 downto 0)
    );
    end component LPM_MULT;

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
    
    signal p_logic : std_logic_vector(31 downto 0);

begin

    gen : if N_CLOCKS = 0 generate
        compute_product : LPM_MULT port map (
            dataa => std_logic_vector(to_signed(a, 32)),
            datab => std_logic_vector(to_signed(b, 32)),
            result => p_logic
        );
        done <= start;
    else generate
        compute_product : LPM_MULT port map (
            clock => clock,
            aclr => not reset_n,
            dataa => std_logic_vector(to_signed(a, 32)),
            datab => std_logic_vector(to_signed(b, 32)),
            result => p_logic
        );
        delay : n_delay port map (
            clock => clock,
            reset_n => reset_n,
            i => start,
            o => done
        );
    end generate;
    
    p <= to_integer(signed(p_logic));
    
end architecture rtl;
