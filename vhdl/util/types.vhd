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

package avalonmm_types is

    type avalonmm_write_from_master_t is record
        address     : std_logic_vector(28 downto 0);
        burst_count : std_logic_vector(7 downto 0);
        write_data  : std_logic_vector(63 downto 0);
        byte_enable : std_logic_vector(7 downto 0);
        write_cmd   : std_logic;
    end record avalonmm_write_from_master_t;

    type avalonmm_write_to_master_t is record
        wait_request : std_logic;
    end record avalonmm_write_to_master_t;

    type avalonmm_read_from_master_t is record
        address     : std_logic_vector(28 downto 0);
        burst_count : std_logic_vector(7 downto 0);
        read_cmd    : std_logic;
    end record avalonmm_read_from_master_t;

    type avalonmm_read_to_master_t is record
        wait_request    : std_logic;
        read_data       : std_logic_vector(63 downto 0);
        read_data_valid : std_logic;
    end record avalonmm_read_to_master_t;

    type avalonmm_write_t is record
        from_master : avalonmm_write_from_master_t;
        to_master   : avalonmm_write_to_master_t;
    end record avalonmm_write_t;

    type avalonmm_read_t is record
        from_master : avalonmm_read_from_master_t;
        to_master   : avalonmm_read_to_master_t;
    end record avalonmm_read_t;

    type avalonmm_rw_from_master_t is record
        r : avalonmm_read_from_master_t;
        w : avalonmm_write_from_master_t;
    end record avalonmm_rw_from_master_t;

    type avalonmm_rw_to_master_t is record
        r : avalonmm_read_to_master_t;
        w : avalonmm_write_to_master_t;
    end record avalonmm_rw_to_master_t;

    type avalonmm_rw_t is record
        from_master : avalonmm_rw_from_master_t;
        to_master   : avalonmm_rw_to_master_t;
    end record avalonmm_rw_t;

end package avalonmm_types;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package spi_types is

    type spi_from_master_t is record
        clock        : std_logic;
        slave_select : std_logic;
        data         : std_logic;
    end record spi_from_master_t;

    type spi_to_master_t is record
        data : std_logic;
    end record spi_to_master_t;

    type spi_t is record
        from_master : spi_from_master_t;
        to_master   : spi_to_master_t;
    end record spi_t;

end package spi_types;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package logic_types is

    subtype logic1_t is std_logic_vector(1-1 downto 0);
    subtype logic2_t is std_logic_vector(2-1 downto 0);
    subtype logic3_t is std_logic_vector(3-1 downto 0);
    subtype logic4_t is std_logic_vector(4-1 downto 0);
    subtype logic5_t is std_logic_vector(5-1 downto 0);
    subtype logic6_t is std_logic_vector(6-1 downto 0);
    subtype logic7_t is std_logic_vector(7-1 downto 0);
    subtype logic8_t is std_logic_vector(8-1 downto 0);
    subtype logic15_t is std_logic_vector (15-1 downto 0);
    subtype logic16_t is std_logic_vector(16-1 downto 0);
    type logic16_vector_t is array(integer range <>) of logic16_t;

    pure function to_logic1(i : integer) return logic1_t;
    pure function to_logic2(i : integer) return logic2_t;
    pure function to_logic3(i : integer) return logic3_t;
    pure function to_logic4(i : integer) return logic4_t;
    pure function to_logic5(i : integer) return logic5_t;
    pure function to_logic6(i : integer) return logic6_t;
    pure function to_logic7(i : integer) return logic7_t;
    pure function to_logic8(i : integer) return logic8_t;
    pure function to_logic15(i : integer) return logic15_t;
    pure function to_logic16(i : integer) return logic16_t;

    pure function bitwise_contains(flags : std_logic_vector; flag : std_logic_vector) return boolean;

end package logic_types;


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;


package body logic_types is

    pure function to_logic1(i : integer) return logic1_t is
    begin
        return std_logic_vector(to_unsigned(i, 1));
    end function to_logic1;

    pure function to_logic2(i : integer) return logic2_t is
    begin
        return std_logic_vector(to_unsigned(i, 2));
    end function to_logic2;

    pure function to_logic3(i : integer) return logic3_t is
    begin
        return std_logic_vector(to_unsigned(i, 3));
    end function to_logic3;
    
    pure function to_logic4(i : integer) return logic4_t is
    begin
        return std_logic_vector(to_unsigned(i, 4));
    end function to_logic4;

    pure function to_logic5(i : integer) return logic5_t is
    begin
        return std_logic_vector(to_unsigned(i, 5));
    end function to_logic5;

    pure function to_logic6(i : integer) return logic6_t is
    begin
        return std_logic_vector(to_unsigned(i, 6));
    end function to_logic6;

    pure function to_logic7(i : integer) return logic7_t is
    begin
        return std_logic_vector(to_unsigned(i, 7));
    end function to_logic7;

    pure function to_logic8(i : integer) return logic8_t is
    begin
        return std_logic_vector(to_unsigned(i, 8));
    end function to_logic8;
    
    pure function to_logic15(i : integer) return logic15_t is
    begin
        return std_logic_vector(to_unsigned(i, 15));
    end function to_logic15;

    pure function to_logic16(i : integer) return logic16_t is
    begin
        return std_logic_vector(to_unsigned(i, 16));
    end function to_logic16;

    pure function bitwise_contains(flags : std_logic_vector; flag : std_logic_vector) return boolean is
    begin
        return or_reduce(flags and flag) = '1';
    end function bitwise_contains;

end package body logic_types;


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;


package integer_types is

    type integer_vector_t is array(integer range <>) of integer;

    pure function max(a : integer; b : integer) return integer;
    pure function max(v : integer_vector_t) return integer;

    procedure increment_rollover(
        i : inout integer;
        threshold : integer;
        enable : boolean;
        rolled_over : out boolean
    );

    procedure increment(
        i : inout integer;
        enable : boolean
    );

end package integer_types;


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;


package body integer_types is

    pure function max(a : integer; b : integer) return integer is
    begin
        if a > b then return a; else return b; end if;
    end function max;

    pure function max(v : integer_vector_t) return integer is
        variable ret : integer;
    begin
        ret := v(v'left);
        for i in v'range loop
            ret := max(ret, v(i));
        end loop;
        return ret;
    end function max;

    procedure increment_rollover(
        i : inout integer;
        threshold : integer;
        enable : boolean;
        rolled_over : out boolean
    ) is
    begin
        if enable then
            if i + 1 < threshold then
                i := i + 1;
                rolled_over := false;
            else
                i := 0;
                rolled_over := true;
            end if;
        end if;
    end procedure increment_rollover;

    procedure increment(
        i : inout integer;
        enable : boolean
    ) is
    begin
        if enable then
            i := i + 1;
        end if;
    end procedure increment;

end package body integer_types;