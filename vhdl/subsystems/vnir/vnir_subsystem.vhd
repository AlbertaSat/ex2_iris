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

use work.spi_types.all;
use work.sensor_comm_types.all;
use work.vnir_types.all;


entity vnir_subsystem is
    port (
        clock           : in std_logic;
        reset_n         : in std_logic;

        config          : in vnir_config_t;
        config_done     : out std_logic;
        
        do_imaging      : in std_logic;

        num_rows        : out integer;
        rows            : out vnir_rows_t;
        rows_available  : out std_logic;
        
        sensor_clock    : out std_logic;
        sensor_reset    : out std_logic;
        
        spi_out         : out spi_from_master_t;
        spi_in          : in spi_to_master_t;
        
        frame_request   : out std_logic;
        lvds            : in vnir_lvds_t
    );
end entity vnir_subsystem;
