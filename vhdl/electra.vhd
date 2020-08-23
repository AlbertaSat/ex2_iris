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
use work.avalonmm;
use work.vnir;
use work.swir_types.all;
use work.sdram;
use work.fpga_types.all;

entity electra is
end electra;


architecture rtl of electra is

	component thing
	port (
		clk_clk                           : in  std_logic                      := '0';             --                   clk.clk
		hps_0_f2h_sdram0_data_address     : in  std_logic_vector(27 downto 0)  := (others => '0'); -- hps_0_f2h_sdram0_data.address
		hps_0_f2h_sdram0_data_burstcount  : in  std_logic_vector(7 downto 0)   := (others => '0'); --                      .burstcount
		hps_0_f2h_sdram0_data_waitrequest : out std_logic;                                         --                      .waitrequest
		hps_0_f2h_sdram0_data_writedata   : in  std_logic_vector(127 downto 0) := (others => '0'); --                      .writedata
		hps_0_f2h_sdram0_data_byteenable  : in  std_logic_vector(15 downto 0)  := (others => '0'); --                      .byteenable
		hps_0_f2h_sdram0_data_write       : in  std_logic                      := '0';             --                      .write
		reset_reset_n                     : in  std_logic                      := '0'              --                 reset.reset_n
    );
    end component thing;

    component sdram_subsystem
    port (
        --Control signals
        clock               : in std_logic;
        reset_n             : in std_logic;

        --VNIR row signals
        vnir_rows_available : in std_logic;
        vnir_num_rows       : in integer;
        vnir_rows           : in vnir.row_t;
        
        --SWIR row signals
        swir_row_available  : in std_logic;
        swir_num_rows       : in integer;
        swir_row            : in swir_row_t;
        
        timestamp           : in timestamp_t;
        mpu_memory_change   : in sdram.address_block_t;
        config_in           : in sdram.config_to_sdram_t;
        start_config        : in std_logic;
        config_out          : out sdram.memory_state_t;
        config_done         : out std_logic;
        img_config_done     : out std_logic;
        
        sdram_busy          : out std_logic;
        sdram_error         : out sdram.error_t;
        
        sdram_avalon_out    : out avalonmm.from_master_t;
        sdram_avalon_in     : in avalonmm.to_master_t
    );
    end component;

    signal clock    : std_logic;  -- Main clock
    signal reset_n  : std_logic;  -- Main reset
    
    -- vnir <=> sdram
    signal vnir_rows : vnir.row_t;
    signal vnir_rows_available : std_logic;

    -- vnir <=> sdram, fpga
    signal vnir_num_rows : integer;

    -- swir <=> sdram, fpga
    signal swir_num_rows : integer;

    -- swir <=> sdram
    signal swir_row : swir_row_t;
    signal swir_row_available : std_logic;

    -- fpga <=> sdram
    signal timestamp : timestamp_t;
    signal start_config : std_logic;
    signal mpu_memory_change : sdram.address_block_t;
    signal sdram_config : sdram.config_to_sdram_t;
    signal sdram_partitions : sdram.memory_state_t;
    signal sdram_config_done : std_logic;
    signal sdram_img_config_done : std_logic;
    signal sdram_busy : std_logic;
    signal sdram_error : sdram.error_t;

    -- sdram <=> RAM
    signal sdram_avalon : avalonmm.bus_t;

    attribute keep : boolean;

    attribute keep of clock                 : signal is true;
    attribute keep of reset_n               : signal is true;
    attribute keep of vnir_rows             : signal is true;
    attribute keep of vnir_rows_available   : signal is true;
    attribute keep of vnir_num_rows         : signal is true;
    attribute keep of swir_num_rows         : signal is true;
    attribute keep of swir_row              : signal is true;
    attribute keep of swir_row_available    : signal is true;
    attribute keep of timestamp             : signal is true;
    attribute keep of start_config          : signal is true;
    attribute keep of mpu_memory_change     : signal is true;
    attribute keep of sdram_config          : signal is true;
    attribute keep of sdram_partitions      : signal is true;
    attribute keep of sdram_config_done     : signal is true;
    attribute keep of sdram_img_config_done : signal is true;
    attribute keep of sdram_busy            : signal is true;
    attribute keep of sdram_error           : signal is true;
    attribute keep of sdram_avalon          : signal is true;

begin

	u0 : thing port map (
		clk_clk                             => clock,
		hps_0_f2h_sdram0_data_address       => sdram_avalon.from_master.address,
		hps_0_f2h_sdram0_data_burstcount    => sdram_avalon.from_master.burst_count,
		hps_0_f2h_sdram0_data_waitrequest   => sdram_avalon.to_master.wait_request,
		hps_0_f2h_sdram0_data_writedata     => sdram_avalon.from_master.write_data,
		hps_0_f2h_sdram0_data_byteenable    => sdram_avalon.from_master.byte_enable,
		hps_0_f2h_sdram0_data_write         => sdram_avalon.from_master.write_cmd,
        reset_reset_n                       => reset_n
    );

    sdram_subsystem_component : sdram_subsystem port map (
        clock => clock,
        reset_n => reset_n,
        vnir_rows_available => vnir_rows_available,
        vnir_num_rows => vnir_num_rows,
        vnir_rows => vnir_rows,
        swir_row_available => swir_row_available,
        swir_num_rows => swir_num_rows,
        swir_row => swir_row,
        timestamp => timestamp,
        mpu_memory_change => mpu_memory_change,
        config_in => sdram_config,
        start_config => start_config,
        config_out => sdram_partitions,
        config_done => sdram_config_done,
        img_config_done => sdram_img_config_done,
        sdram_busy => sdram_busy,
        sdram_error => sdram_error,
        sdram_avalon_out => sdram_avalon.from_master,
        sdram_avalon_in => sdram_avalon.to_master
    );
end;
