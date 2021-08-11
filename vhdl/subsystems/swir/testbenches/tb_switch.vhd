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

-- Testbench to simulate behaviour of ADG719BRMZ 2:1 Mux/SPDT Switch

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_switch is
	port (	-- The switch will be used on analog data, which is modelled as an integer type
		s1					: in integer;  -- Switch input 1
		s2					: in integer;  -- Switch input 2
        in_pin			  	: in std_logic;  -- Switch select signal
		d				    : out integer  -- Switch output
    );
end entity;

architecture sim of tb_switch is 
	
begin
	
	d <= s1 when in_pin = '0' else
		 s2 when in_pin = '1' else
		 0;
		
end architecture;