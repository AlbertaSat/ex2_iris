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

use work.vnir_types.all;  -- Gives outputs to the VNIR subsystem
use work.swir_types.all;  -- Gives outputs from SWIR subsystem
use work.sdram_types.all;  -- Gives outptu to sdram subsystem
use work.fpga_types.all;  -- For timestamp_t


entity fpga_subsystem is
    port (
        clock                    : in std_logic;
        reset_n                  : in std_logic;
        
        vnir_config              : out vnir_config_t;
        vnir_config_done         : in std_logic;
        swir_config              : out swir_config_t;
        swir_config_done         : in std_logic;
        sdram_config_in          : in sdram_config_from_sdram_t;
        sdram_config_out         : out sdram_config_to_sdram_t;
        sdram_config_done        : in std_logic;

        vnir_num_rows            : in integer;
        swir_num_rows            : in integer;

        do_imaging               : out std_logic;
        
        timestamp                : out timestamp_t;
        init_timestamp           : in timestamp_t;

        image_request            : in std_logic;
        imaging_duration         : in integer
    );
end entity fpga_subsystem;

architecture rtl of fpga_subsystem is
begin
end architecture rtl;
