library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.spi_types.all;
use work.avalonmm_types.all;
use work.vnir_types.all;
use work.swir_types.all;
use work.sdram_types.all;
use work.fpga_types.all;

entity memory_map_tb is
end entity;

architecture sim of memory_map_tb is
    constant clk_freq : integer := 20000000;
    constant clk_period : time := 1000 ms / clk_freq;

    signal clk : std_logic := '0';
    signal reset_n : std_logic := '0';

    --SDRAM config signals to and from the FPGA
    signal config              : sdram_config_to_sdram_t := (
        memory_base => to_signed(0, ADDRESS_LENGTH),
        memory_bounds => to_signed(0, ADDRESS_LENGTH)
    );
    signal memory_state        : sdram_partitions_t;

    signal start_config        : std_logic := '0';
    signal config_done         : std_logic;
    signal img_config_done     : std_logic;

    --Image Config signals
    signal number_swir_rows    : natural := 0;
    signal number_vnir_rows    : natural := 0;

    --Ouput image row address config
    signal next_row_type       : sdram_next_row_fed_t := no_row;
    signal next_row_req        : std_logic := '0';
    signal output_address      : sdram_address_t;

    --Read data to be read from sdram due to mpu interaction
    signal sdram_error         : sdram_error_t := no_error;

    component memory_map port(
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
        output_address      : out sdram_address_t;

        --Read data to be read from sdram due to mpu interaction
        sdram_error         : out sdram_error_t);
    end component;
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
        sdram_error => sdram_error
    );

    clk <= not(clk) after clk_period / 2;

    process is
    begin
        wait for 2 * clk_period;

        --taking out of reset
        reset_n <= '1';
        wait until rising_edge(clk);

        --CmdCrtr asking for first row immediately, not sending data
        wait until rising_edge(clk);

        --Setting the memory bases
        config.memory_base <= to_signed(16#200#, ADDRESS_LENGTH);
        config.memory_bounds <= to_signed(16#2000000#, ADDRESS_LENGTH);
        start_config <= '1';

        --Waiting a bit
        wait until (config_done = '1');
        wait until rising_edge(clk);
        next_row_req <= '1';

        --Setting the number of rows for the incoming image
        number_vnir_rows <= 3;
        number_swir_rows <= 2;
        wait until (img_config_done = '1');
        next_row_req <= '0';

        --Additionally, next row type waiting is red, then waiting 10 clks for next_row_req as it transmits vnir header
        next_row_type <= red_row;
        wait for clk_period * 10;
        next_row_req <= '1';

        --Waiting for address to change
        wait for clk_period * 4;

        --Output is now swir header
        next_row_req <= '0';
        wait for clk_period * 10;

        --Output is now red row, blue row next
        next_row_req <= '1';
        wait for clk_period * 4;
        next_row_type <= blue_row;
        next_row_req <= '0';
        wait for clk_period * 10;

        --Output is now blue row, another red row next
        next_row_req <= '1';
        wait for clk_period * 3;
        next_row_type <= red_row;
        next_row_req <= '0';
        wait for clk_period * 10;

        --Output is now red row, another red row next
        next_row_req <= '1';
        wait for clk_period * 3;
        next_row_req <= '0';
        wait for clk_period * 10;

        --Output is now red row, nir row next
        next_row_req <= '1';
        wait for clk_period * 3;
        next_row_type <= nir_row;
        next_row_req <= '0';
        wait for clk_period * 10;
        
        --Output is now nir row, swir row next
        next_row_req <= '1';
        wait for clk_period * 3;
        next_row_type <= swir_row;
        next_row_req <= '0';
        wait for clk_period * 10;
        
        --Output is now swir row, blue row next
        next_row_req <= '1';
        wait for clk_period * 3;
        next_row_type <= blue_row;
        next_row_req <= '0';
        wait for clk_period * 10;
        
        --Output is now blue row, blue row next
        next_row_req <= '1';
        wait for clk_period * 3;
        next_row_req <= '0';
        wait for clk_period * 10;
        
        --Output is now blue row, swir row next
        next_row_req <= '1';
        wait for clk_period * 3;
        next_row_type <= swir_row;
        next_row_req <= '0';
        wait for clk_period * 10;
        
        --Output is now swir row, nir row next
        next_row_req <= '1';
        wait for clk_period * 3;
        next_row_type <= nir_row;
        next_row_req <= '0';
        wait for clk_period * 10;
        
        --Output is now nir row, nir row next to finish
        next_row_req <= '1';
        wait for clk_period * 3;
        next_row_req <= '0';
        wait for clk_period * 10;
        next_row_req <= '1';
        wait for clk_period * 3;
        next_row_req <= '0';
        wait for clk_period * 10;
        next_row_req <= '1';
        wait for clk_period * 3;
        next_row_req <= '0';

    end process;
end architecture;