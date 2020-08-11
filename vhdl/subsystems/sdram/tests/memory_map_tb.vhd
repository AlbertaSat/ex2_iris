library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.spi_types.all;
use work.avalonmm_types.all;
use work.vnir_types.all;
use work.swir_types.all;
use work.sdram_types.all;
use work.fpga_types.all;

entity part_reg_tb is
end entity;

architecture sim of part_reg_tb is
    constant clk_freq : integer := 20000000;
    constant clk_period : time := 1000 ms / clk_freq;

    signal clk : std_logic := '0';
    signal reset_n : std_logic := '0';

    --SDRAM config signals to and from the FPGA
    signal config              : sdram_config_to_sdram_t;
    signal memory_state        : sdram_partitions_t;

    signal start_config        : std_logic;
    signal config_done         : std_logic;
    signal img_config_done     : std_logic;

    --Image Config signals
    signal number_swir_rows    : natural;
    signal number_vnir_rows    : natural;

    --Ouput image row address config
    signal next_row_type       : sdram_next_row_fed_t;
    signal next_row_req        : std_logic;
    signal output_address      : sdram_address;

    --Read data to be read from sdram due to mpu interaction
    signal sdram_error         : sdram_error_t;
    signal read_data           : avalonmm_read_to_master_t

    component memory_map is port(
        --Control signals
        clock               : in std_logic;
        reset_n             : in std_logic;

        --SDRAM config signals to and from the FPGA
        config              : in sdram_config_to_sdram_t;
        memory_state        : out sdram_partitions_t;

        start_config        : in std_logic;
        config_done         : out std_logic;
        img_config_done     : out std_logic;

        --Image Config signals
        number_swir_rows    : in natural;
        number_vnir_rows    : in natural;

        --Ouput image row address config
        next_row_type       : in sdram_next_row_fed_t;
        next_row_req        : in std_logic;
        output_address      : out sdram_address;

        --Read data to be read from sdram due to mpu interaction
        sdram_error         : out sdram_error_t
    );
begin
    memory_map_comp : memory_map port map (
        clock => clk,
        reset_n => reset_n,
        config => config,
        memory_state => memory_state,
        start_config => start_config,
        config_done => config_done,
        img_config_done => img_config_done,
        number_vnir_rows => number_vnir_rows,
        number_swir_rows => number_swir_rows,
        next_row_type => next_row_type,
        next_row_req => next_row_req,
        output_address => output_address,
        sdram_errer => sdram_error
    );

    