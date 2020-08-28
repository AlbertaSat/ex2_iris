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

use work.vnir;  -- Gives outputs to the VNIR subsystem
use work.swir_types.all;  -- Gives outputs from SWIR subsystem
use work.sdram_types.all;  -- Gives outptu to sdram subsystem
use work.fpga_types.all;  -- For timestamp_t
use work.spi_types.all;

entity fpga_subsystem is
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
end entity fpga_subsystem;

architecture rtl of fpga_subsystem is

    component vnir_subsystem_avalonmm is
    port (
        clock               : in std_logic;
        reset_n             : in std_logic;

        avs_address         : in  std_logic_vector(7 downto 0);
        avs_read            : in  std_logic := '0';
        avs_readdata        : out std_logic_vector(31 downto 0);
        avs_write           : in  std_logic := '0';
        avs_writedata       : in  std_logic_vector(31 downto 0);
        avs_irq             : out std_logic;

        sensor_clock        : in std_logic;
        sensor_power        : out std_logic;
        sensor_clock_enable : out std_logic;
        sensor_reset_n      : out std_logic;

        row                 : out vnir.row_t;
        row_available       : out vnir.row_type_t;
        
        spi_out             : out spi_from_master_t;
        spi_in              : in spi_to_master_t;
        
        frame_request       : out std_logic;
        exposure_start      : out std_logic;
        lvds                : in vnir.lvds_t
    );
    end component vnir_subsystem_avalonmm;

    component interconnect is
    port (
        clock_clk                      : in    std_logic                     := 'X';             -- clk
        memory_mem_a                   : out   std_logic_vector(14 downto 0);                    -- mem_a
        memory_mem_ba                  : out   std_logic_vector(2 downto 0);                     -- mem_ba
        memory_mem_ck                  : out   std_logic;                                        -- mem_ck
        memory_mem_ck_n                : out   std_logic;                                        -- mem_ck_n
        memory_mem_cke                 : out   std_logic;                                        -- mem_cke
        memory_mem_cs_n                : out   std_logic;                                        -- mem_cs_n
        memory_mem_ras_n               : out   std_logic;                                        -- mem_ras_n
        memory_mem_cas_n               : out   std_logic;                                        -- mem_cas_n
        memory_mem_we_n                : out   std_logic;                                        -- mem_we_n
        memory_mem_reset_n             : out   std_logic;                                        -- mem_reset_n
        memory_mem_dq                  : inout std_logic_vector(31 downto 0) := (others => 'X'); -- mem_dq
        memory_mem_dqs                 : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs
        memory_mem_dqs_n               : inout std_logic_vector(3 downto 0)  := (others => 'X'); -- mem_dqs_n
        memory_mem_odt                 : out   std_logic;                                        -- mem_odt
        memory_mem_dm                  : out   std_logic_vector(3 downto 0);                     -- mem_dm
        memory_oct_rzqin               : in    std_logic                     := 'X';             -- oct_rzqin
        reset_reset_n                  : in    std_logic                     := 'X';             -- reset_n
        sdram_controller_avm_address   : out   std_logic_vector(7 downto 0);                     -- address
        sdram_controller_avm_read      : out   std_logic;                                        -- read
        sdram_controller_avm_readdata  : in    std_logic_vector(31 downto 0) := (others => 'X'); -- readdata
        sdram_controller_avm_write     : out   std_logic;                                        -- write
        sdram_controller_avm_writedata : out   std_logic_vector(31 downto 0);                    -- writedata
        sdram_controller_avm_irq_irq   : in    std_logic                     := 'X';             -- irq
        swir_controller_avm_address    : out   std_logic_vector(7 downto 0);                     -- address
        swir_controller_avm_read       : out   std_logic;                                        -- read
        swir_controller_avm_readdata   : in    std_logic_vector(31 downto 0) := (others => 'X'); -- readdata
        swir_controller_avm_write      : out   std_logic;                                        -- write
        swir_controller_avm_writedata  : out   std_logic_vector(31 downto 0);                    -- writedata
        swir_controller_avm_irq_irq    : in    std_logic                     := 'X';             -- irq
        vnir_controller_avm_address    : out   std_logic_vector(7 downto 0);                     -- address
        vnir_controller_avm_read       : out   std_logic;                                        -- read
        vnir_controller_avm_readdata   : in    std_logic_vector(31 downto 0) := (others => 'X'); -- readdata
        vnir_controller_avm_write      : out   std_logic;                                        -- write
        vnir_controller_avm_writedata  : out   std_logic_vector(31 downto 0);                    -- writedata
        vnir_controller_avm_irq_irq    : in    std_logic                     := 'X';             -- irq
        pll_0_refclk_clk               : in    std_logic                     := 'X';             -- clk
        pll_0_locked_export            : out   std_logic;                                        -- export
        vnir_sensor_clock_clk          : out   std_logic                                         -- clk
    );
    end component interconnect;

    -- Subsystem reset -- held low until plls are locked
    signal subsystem_reset_n    : std_logic;

    -- PLL signals
    signal pll_locked           : std_logic;

    -- For connecting VNIR subsystem with AvalonMM interface
    signal vnir_av_address      : std_logic_vector(7 downto 0);
    signal vnir_av_read         : std_logic;
    signal vnir_av_readdata     : std_logic_vector(31 downto 0);
    signal vnir_av_write        : std_logic;
    signal vnir_av_writedata    : std_logic_vector(31 downto 0);
    signal vnir_av_irq          : std_logic;

    -- For connecting SWIR subsystem with AvalonMM interface
    signal swir_av_address      : std_logic_vector(7 downto 0);
    signal swir_av_read         : std_logic;
    signal swir_av_readdata     : std_logic_vector(31 downto 0);
    signal swir_av_write        : std_logic;
    signal swir_av_writedata    : std_logic_vector(31 downto 0);
    signal swir_av_irq          : std_logic;

    -- For connecting SDRAM subsystem with AvalonMM interface
    signal sdram_av_address     : std_logic_vector(7 downto 0);
    signal sdram_av_read        : std_logic;
    signal sdram_av_readdata    : std_logic_vector(31 downto 0);
    signal sdram_av_write       : std_logic;
    signal sdram_av_writedata   : std_logic_vector(31 downto 0);
    signal sdram_av_irq         : std_logic;

    -- VNIR subsystem => SDRAM subsystem
    signal vnir_row             : vnir.row_t;
    signal vnir_row_available   : vnir.row_type_t;

    -- VNIR sensor clock signals
    signal vnir_sensor_clock_ungated : std_logic;
    signal vnir_sensor_clock_enable  : std_logic;

    attribute keep: boolean;
    -- Temporary, remove when SDRAM subsystem is added
    attribute keep of vnir_row              : signal is true;
    attribute keep of vnir_row_available    : signal is true;
    attribute keep of sdram_av_address      : signal is true;
    attribute keep of sdram_av_read         : signal is true;
    attribute keep of sdram_av_readdata     : signal is true;
    attribute keep of sdram_av_write        : signal is true;
    attribute keep of sdram_av_writedata    : signal is true;
    attribute keep of sdram_av_irq          : signal is true;
    -- Temporary, remove when SWIR subsystem is added
    attribute keep of swir_av_address       : signal is true;
    attribute keep of swir_av_read          : signal is true;
    attribute keep of swir_av_readdata      : signal is true;
    attribute keep of swir_av_write         : signal is true;
    attribute keep of swir_av_writedata     : signal is true;
    attribute keep of swir_av_irq           : signal is true;

begin

    -- Two-phase reset is required -- can't exit subsystem resets until plls have locked
    subsystem_reset_n <= '0' when reset_n = '0' or pll_locked = '0' else '1';

    vnir_cmp : vnir_subsystem_avalonmm port map (
        clock               => clock,
        reset_n             => subsystem_reset_n,

        avs_address         => vnir_av_address,
        avs_read            => vnir_av_read,
        avs_readdata        => vnir_av_readdata,
        avs_write           => vnir_av_write,
        avs_writedata       => vnir_av_writedata,
        avs_irq             => vnir_av_irq,

        sensor_clock        => vnir_sensor_clock_ungated,
        sensor_power        => vnir_sensor_power,
        sensor_clock_enable => vnir_sensor_clock_enable,
        sensor_reset_n      => vnir_sensor_reset_n,

        row                 => vnir_row,
        row_available       => vnir_row_available,

        spi_out             => vnir_spi_out,
        spi_in              => vnir_spi_in,

        frame_request       => vnir_frame_request,
        exposure_start      => vnir_exposure_start,
        lvds                => vnir_lvds
    );

    vnir_sensor_clock <= vnir_sensor_clock_ungated and vnir_sensor_clock_enable;

    interconnect_cmp : interconnect port map (
        clock_clk                       => clock,
        reset_reset_n                   => reset_n,
        
        memory_mem_a                    => HPS_DDR3_ADDR,
        memory_mem_ba                   => HPS_DDR3_BA,
        memory_mem_ck                   => HPS_DDR3_CK_P,
        memory_mem_ck_n                 => HPS_DDR3_CK_N,
        memory_mem_cke                  => HPS_DDR3_CKE,
        memory_mem_cs_n                 => HPS_DDR3_CS_N,
        memory_mem_ras_n                => HPS_DDR3_RAS_N,
        memory_mem_cas_n                => HPS_DDR3_CAS_N,
        memory_mem_we_n                 => HPS_DDR3_WE_N,
        memory_mem_reset_n              => HPS_DDR3_RESET_N,
        memory_mem_dq                   => HPS_DDR3_DQ,
        memory_mem_dqs                  => HPS_DDR3_DQS_P,
        memory_mem_dqs_n                => HPS_DDR3_DQS_N,
        memory_mem_odt                  => HPS_DDR3_ODT,
        memory_mem_dm                   => HPS_DDR3_DM,
        memory_oct_rzqin                => HPS_DDR3_RZQ,

        sdram_controller_avm_address    => sdram_av_address,
        sdram_controller_avm_read       => sdram_av_read,
        sdram_controller_avm_readdata   => sdram_av_readdata,
        sdram_controller_avm_write      => sdram_av_write,
        sdram_controller_avm_writedata  => sdram_av_writedata,
        sdram_controller_avm_irq_irq    => sdram_av_irq,
        
        swir_controller_avm_address     => swir_av_address,
        swir_controller_avm_read        => swir_av_read,
        swir_controller_avm_readdata    => swir_av_readdata,
        swir_controller_avm_write       => swir_av_write,
        swir_controller_avm_writedata   => swir_av_writedata,
        swir_controller_avm_irq_irq     => swir_av_irq,
        
        vnir_controller_avm_address     => vnir_av_address,
        vnir_controller_avm_read        => vnir_av_read,
        vnir_controller_avm_readdata    => vnir_av_readdata,
        vnir_controller_avm_write       => vnir_av_write,
        vnir_controller_avm_writedata   => vnir_av_writedata,
        vnir_controller_avm_irq_irq     => vnir_av_irq,

        pll_0_refclk_clk                => pll_ref_clock,
        pll_0_locked_export             => pll_locked,
        vnir_sensor_clock_clk           => vnir_sensor_clock_ungated
    );

end architecture rtl;
