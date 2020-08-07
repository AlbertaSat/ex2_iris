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
use work.vnir_top;
use work.vnir_common;
use work.swir_types.all;
use work.sdram_types.all;
use work.fpga_types.all;

entity electra is
port (
    clock                    : in std_logic;
    pll_ref_clock            : in std_logic;

    -- vnir <=> sensor
    vnir_sensor_power        : out std_logic;
    vnir_sensor_clock        : out std_logic;
    vnir_sensor_reset_n      : out std_logic;
    vnir_spi_out             : out spi_from_master_t;
    vnir_spi_in              : in spi_to_master_t;
    vnir_frame_request       : out std_logic;
    vnir_exposure_start      : out std_logic;
    vnir_lvds                : in vnir_common.lvds_t
);
end entity electra;


architecture rtl of electra is
    component soc_system
    port (
        pll_0_refclk_clk    : in  std_logic := 'X'; -- clk
        pll_0_locked_export : out std_logic;        -- export
        pll_0_outclk0_clk   : out std_logic;        -- clk
        pll_0_reset_reset   : in  std_logic := 'X'  -- reset
    );
    end component;

    component vnir_subsystem
    port (
        clock               : in std_logic;
        reset_n             : in std_logic;
        sensor_clock        : in std_logic;
        sensor_clock_locked : in std_logic;
        sensor_power        : out std_logic;
        sensor_clock_enable : out std_logic;
        sensor_reset_n      : out std_logic;
        config              : in vnir_top.config_t;
        config_done         : out std_logic;
        do_imaging          : in std_logic;
        num_rows            : out integer;
        row                 : out vnir_common.row_t;
        row_available       : out vnir_common.row_type_t;
        spi_out             : out spi_from_master_t;
        spi_in              : in spi_to_master_t;
        frame_request       : out std_logic;
        exposure_start      : out std_logic;
        lvds                : in vnir_common.lvds_t
    );
    end component;

    signal reset_n  : std_logic;  -- Main reset

    -- fpga <=> vnir, swir
    signal do_imaging : std_logic;

    -- SoC system <=> vnir
    signal vnir_sensor_clock_s : std_logic;
    signal vnir_sensor_clock_locked : std_logic;
    signal vnir_sensor_clock_enable : std_logic;

    -- fpga <=> vnir
    signal vnir_config : vnir_top.config_t;
    signal vnir_config_done : std_logic;
    
    -- vnir <=> sdram
    signal vnir_row : vnir_common.row_t;
    signal vnir_row_available : vnir_common.row_type_t;

    -- vnir <=> sdram, fpga
    signal vnir_num_rows : integer;

begin
    soc_system_component : soc_system port map (
        pll_0_refclk_clk    => pll_ref_clock,
        pll_0_locked_export => vnir_sensor_clock_locked,
        pll_0_outclk0_clk   => vnir_sensor_clock_s,
        pll_0_reset_reset   => reset_n
    );

    vnir_subsystem_component : vnir_subsystem port map (
        clock => clock,
        reset_n => reset_n,
        sensor_clock => vnir_sensor_clock_s,
        sensor_clock_locked => vnir_sensor_clock_locked,
        sensor_power => vnir_sensor_power,
        sensor_clock_enable => vnir_sensor_clock_enable,
        sensor_reset_n => vnir_sensor_reset_n,
        config => vnir_config,
        config_done => vnir_config_done,
        do_imaging => do_imaging,
        num_rows => vnir_num_rows,
        row => vnir_row,
        row_available => vnir_row_available,
        spi_out => vnir_spi_out,
        spi_in => vnir_spi_in,
        frame_request => vnir_frame_request,
        exposure_start => vnir_exposure_start,
        lvds => vnir_lvds
    );

    vnir_sensor_clock <= vnir_sensor_clock_s and vnir_sensor_clock_enable;

end architecture rtl;
