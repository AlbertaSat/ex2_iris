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
use work.avalonmm_types.all;
use work.vnir_types.all;
use work.swir_types.all;
use work.sdram_types.all;
use work.fpga_types.all;

entity imaging_buffer is
    port(
        --Control Signals
        clock           : in std_logic;
        reset_n         : in std_logic;

        --Rows of Data
        vnir_rows       : in vnir_rows_t;
        swir_row        : in swir_row_t;

        --Rows out
        vnir_row_out    : out vnir_row_t;
        swir_row_out    : out swir_row_t;
        row_request     : in std_logic;

        --Flag signals
        swir_row_ready  : in std_logic;
        vnir_row_ready  : in vnir_row_available_t;
        header_sent     : in std_logic
    );
end entity imaging_buffer;

architecture rtl of imaging_buffer is

begin
    