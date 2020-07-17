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

entity electra is
port (
    clock                    : in std_logic;
    ref_clock                : in std_logic;

    -- vnir <=> sensor
    vnir_sensor_clock        : out std_logic;
    vnir_sensor_reset        : out std_logic;
    vnir_spi_out             : out spi_from_master_t;
    vnir_spi_in              : in spi_to_master_t;
    vnir_frame_request       : out std_logic;
    vnir_exposure_start      : out std_logic;
    vnir_lvds                : in vnir_lvds_t;
    
    -- From QSys
    memory_mem_a             : out   std_logic_vector(12 downto 0);
    memory_mem_ba            : out   std_logic_vector(2 downto 0);
    memory_mem_ck            : out   std_logic;
    memory_mem_ck_n          : out   std_logic;
    memory_mem_cke           : out   std_logic;
    memory_mem_cs_n          : out   std_logic;
    memory_mem_ras_n         : out   std_logic;
    memory_mem_cas_n         : out   std_logic;
    memory_mem_we_n          : out   std_logic;
    memory_mem_reset_n       : out   std_logic;
    memory_mem_dq            : inout std_logic_vector(7 downto 0);
    memory_mem_dqs           : inout std_logic;
    memory_mem_dqs_n         : inout std_logic;
    memory_mem_odt           : out   std_logic;
    memory_mem_dm            : out   std_logic;
    memory_oct_rzqin         : in    std_logic
);
end entity electra;


architecture rtl of electra is
    component soc_system
    port (
        clock_clk                : in  std_logic;
        reset_reset_n            : in  std_logic;

        ref_clock_clk            : in std_logic;

        vnir_sensor_clock_clk    : out std_logic;
        vnir_sensor_clock_locked_export : out std_logic;

        sdram_write_address      : in  std_logic_vector(28 downto 0);
        sdram_write_burstcount   : in  std_logic_vector(7 downto 0);
        sdram_write_waitrequest  : out std_logic;
        sdram_write_writedata    : in  std_logic_vector(63 downto 0);
        sdram_write_byteenable   : in  std_logic_vector(7 downto 0);
        sdram_write_write        : in  std_logic;
        sdram_read_address       : in  std_logic_vector(28 downto 0);
        sdram_read_burstcount    : in  std_logic_vector(7 downto 0);
        sdram_read_waitrequest   : out std_logic;
        sdram_read_readdata      : out std_logic_vector(63 downto 0);
        sdram_read_readdatavalid : out std_logic;
        sdram_read_read          : in  std_logic;

        memory_mem_a             : out   std_logic_vector(12 downto 0);
        memory_mem_ba            : out   std_logic_vector(2 downto 0);
        memory_mem_ck            : out   std_logic;
        memory_mem_ck_n          : out   std_logic;
        memory_mem_cke           : out   std_logic;
        memory_mem_cs_n          : out   std_logic;
        memory_mem_ras_n         : out   std_logic;
        memory_mem_cas_n         : out   std_logic;
        memory_mem_we_n          : out   std_logic;
        memory_mem_reset_n       : out   std_logic;
        memory_mem_dq            : inout std_logic_vector(7 downto 0);
        memory_mem_dqs           : inout std_logic;
        memory_mem_dqs_n         : inout std_logic;
        memory_mem_odt           : out   std_logic;
        memory_mem_dm            : out   std_logic;
        memory_oct_rzqin         : in    std_logic
    );
    end component;

    component vnir_subsystem
    port (
        clock               : in std_logic;
        reset_n             : in std_logic;
        sensor_clock        : in std_logic;
        sensor_clock_locked : in std_logic;
        sensor_reset        : out std_logic;
        config              : in vnir_config_t;
        config_done         : out std_logic;
        do_imaging          : in std_logic;
        num_rows            : out integer;
        row                 : out vnir_row_t;
        row_available       : out vnir_row_type_t;
        spi_out             : out spi_from_master_t;
        spi_in              : in spi_to_master_t;
        frame_request       : out std_logic;
        exposure_start      : out std_logic;
        lvds                : in vnir_lvds_t
    );
    end component;

    component swir_subsystem
    port (
        clock           : in std_logic;
        reset_n         : in std_logic;
        config          : in swir_config_t;
        control         : out swir_control_t;
        config_done     : out std_logic;
        do_imaging      : in std_logic;
        num_rows        : out integer;
        row             : out swir_row_t;
        row_available   : out std_logic;
        sensor_clock    : out std_logic;
        sensor_reset    : out std_logic;
        video           : in std_logic
    );
    end component;

    component sdram_subsystem
    port (
        clock               : in std_logic;
        reset_n             : in std_logic;
        vnir_row_available  : in vnir_row_type_t;
        vnir_num_rows       : in integer;
        vnir_row            : in vnir_row_t;
        swir_row_available  : in std_logic;
        swir_num_rows       : in integer;
        swir_row            : in swir_row_t;
        timestamp           : in timestamp_t;
        mpu_memory_change   : in sdram_address_list_t;
        config_in           : in sdram_config_to_sdram_t;
        config_out          : out sdram_config_from_sdram_t;
        config_done         : out std_logic;
        sdram_busy          : out std_logic;
        sdram_error         : out sdram_error_t;
        sdram_avalon_out    : out avalonmm_rw_from_master_t;
        sdram_avalon_in     : in avalonmm_rw_to_master_t
    );
    end component;

    component fpga_subsystem
    port (
        clock               : in std_logic;
        reset_n             : in std_logic;
        vnir_config         : out vnir_config_t;
        vnir_config_done    : in std_logic;
        swir_config         : out swir_config_t;
        swir_config_done    : in std_logic;
        sdram_config_in     : in sdram_config_from_sdram_t;
        sdram_config_out    : out sdram_config_to_sdram_t;
        sdram_config_done   : in std_logic;
        vnir_num_rows       : in integer;
        swir_num_rows       : in integer;
        do_imaging          : out std_logic;
        timestamp           : out timestamp_t;
        init_timestamp      : in timestamp_t;
        image_request       : in std_logic;
        imaging_duration    : in integer
    );
    end component;

    signal reset_n  : std_logic;  -- Main reset

    -- fpga <=> vnir, swir
    signal do_imaging : std_logic;

    -- SoC system <=> vnir
    signal vnir_sensor_clock_s : std_logic;
    signal vnir_sensor_clock_locked : std_logic;

    -- fpga <=> vnir
    signal vnir_config : vnir_config_t;
    signal vnir_config_done : std_logic;
    
    -- vnir <=> sdram
    signal vnir_row : vnir_row_t;
    signal vnir_row_available : vnir_row_type_t;

    -- vnir <=> sdram, fpga
    signal vnir_num_rows : integer;

    -- swir <=> sdram, fpga
    signal swir_num_rows : integer;

    -- fpga <=> swir
    signal swir_config : swir_config_t;
    signal swir_config_done : std_logic;

    -- swir <=> sdram
    signal swir_row : swir_row_t;
    signal swir_row_available : std_logic;

    -- swir <=> sensor
    signal swir_sensor_clock : std_logic;
    signal swir_sensor_reset : std_logic;
    signal swir_control      : swir_control_t;
    signal swir_video        : std_logic;

    -- fpga <=> sdram
    signal timestamp : timestamp_t;
    signal mpu_memory_change : sdram_address_list_t;
    signal sdram_config : sdram_config_t;
    signal sdram_config_done : std_logic;
    signal sdram_busy : std_logic;
    signal sdram_error : sdram_error_t;

    -- sdram <=> RAM
    signal sdram_avalon : avalonmm_rw_t;

    -- fpga <=> microcontroller
    signal init_timestamp : timestamp_t;
    signal image_request : std_logic;
    signal imaging_duration : integer;
    -- TODO: add on to this

begin
    soc_system_component : soc_system port map (
        clock_clk => clock,
        reset_reset_n => reset_n,
        ref_clock_clk => ref_clock,
        vnir_sensor_clock_clk => vnir_sensor_clock_s,
        vnir_sensor_clock_locked_export => vnir_sensor_clock_locked,
        sdram_write_address => sdram_avalon.from_master.w.address,
        sdram_write_burstcount => sdram_avalon.from_master.w.burst_count,
        sdram_write_waitrequest => sdram_avalon.to_master.w.wait_request,
        sdram_write_writedata => sdram_avalon.from_master.w.write_data,
        sdram_write_byteenable => sdram_avalon.from_master.w.byte_enable,
        sdram_write_write => sdram_avalon.from_master.w.write_cmd,
        sdram_read_address => sdram_avalon.from_master.r.address,
        sdram_read_burstcount => sdram_avalon.from_master.r.burst_count,
        sdram_read_waitrequest => sdram_avalon.to_master.r.wait_request,
        sdram_read_readdata => sdram_avalon.to_master.r.read_data,
        sdram_read_readdatavalid => sdram_avalon.to_master.r.read_data_valid,
        sdram_read_read => sdram_avalon.from_master.r.read_cmd,
        memory_mem_a => memory_mem_a,
        memory_mem_ba => memory_mem_ba,
        memory_mem_ck => memory_mem_ck,
        memory_mem_ck_n => memory_mem_ck_n,
        memory_mem_cke => memory_mem_cke,
        memory_mem_cs_n => memory_mem_cs_n,
        memory_mem_ras_n => memory_mem_ras_n,
        memory_mem_cas_n => memory_mem_cas_n,
        memory_mem_we_n => memory_mem_we_n,
        memory_mem_reset_n => memory_mem_reset_n,
        memory_mem_dq => memory_mem_dq,
        memory_mem_dqs => memory_mem_dqs,
        memory_mem_dqs_n => memory_mem_dqs_n,
        memory_mem_odt => memory_mem_odt,
        memory_mem_dm => memory_mem_dm,
        memory_oct_rzqin => memory_oct_rzqin
    );

    vnir_subsystem_component : vnir_subsystem port map (
        clock => clock,
        reset_n => reset_n,
        sensor_clock => vnir_sensor_clock_s,
        sensor_clock_locked => vnir_sensor_clock_locked,
        sensor_reset => vnir_sensor_reset,
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

    swir_subsystem_component : swir_subsystem port map (
        clock => clock,
        reset_n => reset_n,
        config => swir_config,
        control => swir_control,
        config_done => swir_config_done,
        do_imaging => do_imaging,
        num_rows => swir_num_rows,
        row => swir_row,
        row_available => swir_row_available,
        sensor_clock => swir_sensor_clock,
        sensor_reset => swir_sensor_reset,
        video => swir_video
    );

    sdram_subsystem_component : sdram_subsystem port map (
        clock => clock,
        reset_n => reset_n,
        vnir_row_available => vnir_row_available,
        vnir_num_rows => vnir_num_rows,
        vnir_row => vnir_row,
        swir_row_available => swir_row_available,
        swir_num_rows => swir_num_rows,
        swir_row => swir_row,
        timestamp => timestamp,
        mpu_memory_change => mpu_memory_change,
        config_in => sdram_config.to_sdram,
        config_out => sdram_config.from_sdram,
        config_done => sdram_config_done,
        sdram_busy => sdram_busy,
        sdram_error => sdram_error,
        sdram_avalon_out => sdram_avalon.from_master,
        sdram_avalon_in => sdram_avalon.to_master
    );

    fpga_subsystem_component : fpga_subsystem port map (
        clock => clock,
        reset_n => reset_n,
        vnir_config => vnir_config,
        vnir_config_done => vnir_config_done,
        swir_config => swir_config,
        swir_config_done => swir_config_done,
        sdram_config_in => sdram_config.from_sdram,
        sdram_config_out => sdram_config.to_sdram,
        sdram_config_done => sdram_config_done,
        vnir_num_rows => vnir_num_rows,
        swir_num_rows => swir_num_rows,
        do_imaging => do_imaging,
        timestamp => timestamp,
        init_timestamp => init_timestamp,
        image_request => image_request,
        imaging_duration => imaging_duration
    );

    vnir_sensor_clock <= vnir_sensor_clock_s;

end architecture rtl;
