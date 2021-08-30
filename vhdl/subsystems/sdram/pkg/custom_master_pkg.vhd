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

use work.sdram;
use work.img_buffer_pkg.all; 

package custom_master_pkg is
    
    type to_master_t is record 
        control_fixed_location   : std_logic;
        control_write_length     : std_logic_vector(sdram.ADDRESS_LENGTH-1 downto 0);
        control_write_base       : std_logic_vector(sdram.ADDRESS_LENGTH-1 downto 0);
        control_go               : std_logic;
        user_write_buffer        : std_logic;
        user_buffer_data         : std_logic_vector(FIFO_WORD_LENGTH-1 downto 0);
    end record to_master_t;
    
    type from_master_t is record
        control_done             : std_logic;
        user_buffer_full         : std_logic;
    end record from_master_t;

end package custom_master_pkg;

