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
use work.vnir;
use work.swir_types.all;
use work.sdram_types.all;
use work.fpga_types.all;

entity electra is
port (
    clock                    : in std_logic;
    pll_ref_clock            : in std_logic;

    -- VNIR external ports
    vnir_sensor_power       : out std_logic;
    vnir_sensor_clock       : out std_logic;
    vnir_sensor_reset_n     : out std_logic;
    vnir_spi_out            : out spi_from_master_t;
    vnir_spi_in             : in spi_to_master_t;
    vnir_frame_request      : out std_logic;
    vnir_exposure_start     : out std_logic;
    vnir_lvds               : in vnir.lvds_t;

    -- HPS to DDR3
    HPS_DDR3_ADDR           : out std_logic_vector(14 downto 0);
    HPS_DDR3_BA             : out std_logic_vector(2 downto 0);
    HPS_DDR3_CK_P           : out std_logic;
    HPS_DDR3_CK_N           : out std_logic;
    HPS_DDR3_CKE            : out std_logic;
    HPS_DDR3_CS_N           : out std_logic;
    HPS_DDR3_RAS_N          : out std_logic;
    HPS_DDR3_CAS_N          : out std_logic;
    HPS_DDR3_WE_N           : out std_logic;
    HPS_DDR3_RESET_N        : out std_logic;
    HPS_DDR3_DQ             : inout std_logic_vector(31 downto 0) := (others => 'X');
    HPS_DDR3_DQS_P          : inout std_logic_vector(3 downto 0) := (others => 'X');
    HPS_DDR3_DQS_N          : inout std_logic_vector(3 downto 0) := (others => 'X');
    HPS_DDR3_ODT            : out std_logic;
    HPS_DDR3_DM             : out std_logic_vector(3 downto 0);
    HPS_DDR3_RZQ            : in std_logic := 'X'
);
end entity electra;


architecture rtl of electra is

    component fpga_subsystem is
    port (
        clock                   : in std_logic;
        pll_ref_clock           : in std_logic;
        reset_n                 : in std_logic;

        -- VNIR external ports
        vnir_sensor_power       : out std_logic;
        vnir_sensor_clock       : out std_logic;
        vnir_sensor_reset_n     : out std_logic;
        vnir_spi_out            : out spi_from_master_t;
        vnir_spi_in             : in spi_to_master_t;
        vnir_frame_request      : out std_logic;
        vnir_exposure_start     : out std_logic;
        vnir_lvds               : in vnir.lvds_t;

        -- HPS to DDR3
        HPS_DDR3_ADDR           : out std_logic_vector(14 downto 0);
        HPS_DDR3_BA             : out std_logic_vector(2 downto 0);
        HPS_DDR3_CK_P           : out std_logic;
        HPS_DDR3_CK_N           : out std_logic;
        HPS_DDR3_CKE            : out std_logic;
        HPS_DDR3_CS_N           : out std_logic;
        HPS_DDR3_RAS_N          : out std_logic;
        HPS_DDR3_CAS_N          : out std_logic;
        HPS_DDR3_WE_N           : out std_logic;
        HPS_DDR3_RESET_N        : out std_logic;
        HPS_DDR3_DQ             : inout std_logic_vector(31 downto 0) := (others => 'X');
        HPS_DDR3_DQS_P          : inout std_logic_vector(3 downto 0) := (others => 'X');
        HPS_DDR3_DQS_N          : inout std_logic_vector(3 downto 0) := (others => 'X');
        HPS_DDR3_ODT            : out std_logic;
        HPS_DDR3_DM             : out std_logic_vector(3 downto 0);
        HPS_DDR3_RZQ            : in std_logic := 'X'
    );
    end component fpga_subsystem;

    signal reset_n      : std_logic;
    signal reset_clocks : integer := 10;  -- Hold reset for 10 clock cycles on startup

    attribute keep : boolean;
    attribute keep of reset_n : signal is true;

begin

    process (clock)
    begin
        if rising_edge(clock) then
            if reset_clocks > 0 then
                reset_clocks <= reset_clocks - 1;
                reset_n <= '0';
            else
                reset_n <= '1';
            end if;
        end if;
    end process;

    fpga_cmp : fpga_subsystem port map (
        clock               => clock,
        pll_ref_clock       => pll_ref_clock,
        reset_n             => reset_n,
        vnir_sensor_power   => vnir_sensor_power,
        vnir_sensor_clock   => vnir_sensor_clock,
        vnir_sensor_reset_n => vnir_sensor_reset_n,
        vnir_spi_out        => vnir_spi_out,
        vnir_spi_in         => vnir_spi_in,
        vnir_frame_request  => vnir_frame_request,
        vnir_exposure_start => vnir_exposure_start,
        vnir_lvds           => vnir_lvds,
        HPS_DDR3_ADDR       => HPS_DDR3_ADDR,
        HPS_DDR3_BA         => HPS_DDR3_BA,
        HPS_DDR3_CK_P       => HPS_DDR3_CK_P,
        HPS_DDR3_CK_N       => HPS_DDR3_CK_N,
        HPS_DDR3_CKE        => HPS_DDR3_CKE,
        HPS_DDR3_CS_N       => HPS_DDR3_CS_N,
        HPS_DDR3_RAS_N      => HPS_DDR3_RAS_N,
        HPS_DDR3_CAS_N      => HPS_DDR3_CAS_N,
        HPS_DDR3_WE_N       => HPS_DDR3_WE_N,
        HPS_DDR3_RESET_N    => HPS_DDR3_RESET_N,
        HPS_DDR3_DQ         => HPS_DDR3_DQ,
        HPS_DDR3_DQS_P      => HPS_DDR3_DQS_P,
        HPS_DDR3_DQS_N      => HPS_DDR3_DQS_N,
        HPS_DDR3_ODT        => HPS_DDR3_ODT,
        HPS_DDR3_DM         => HPS_DDR3_DM,
        HPS_DDR3_RZQ        => HPS_DDR3_RZQ
    );

end architecture rtl;
