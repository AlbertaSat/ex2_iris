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

use work.vnir_types.all;
use work.spi_types.all;

-- TODO: reset sensor
-- TODO: Should probably have config delays here


entity sensor_configurer is
port (	
    clock           : in std_logic;
    reset_n         : in std_logic;
    config          : in vnir_config_t;
    start_config    : in std_logic;
    config_done     : out std_logic;	
    spi_out         : out spi_from_master_t;
    spi_in          : in spi_to_master_t;
    sensor_reset    : out std_logic
);
end entity sensor_configurer;


architecture rtl of sensor_configurer is
    component spi_master is
    generic (
        slaves  : integer;  
        d_width : integer
    );
    port (
        clock   : in     std_logic;                             
        reset_n : in     std_logic;                             
        enable  : in     std_logic;                             
        cpol    : in     std_logic;                             
        cpha    : in     std_logic;                             
        cont    : in     std_logic;                             
        clk_div : in     integer;                               
        addr    : in     integer;                               
        tx_data : in     std_logic_vector(15 downto 0);  
        miso    : in     std_logic;                             
        sclk    : buffer std_logic;                             
        ss_n    : buffer std_logic_vector(0 downto 0);   
        mosi    : out    std_logic;                             
        busy    : out    std_logic;                             
        rx_data : out    std_logic_vector(15 downto 0)
    ); 
    end component;

    subtype logic15_t is std_logic_vector (14 downto 0);
    constant reg_data_size : integer := 14;
    type reg_t is array (reg_data_size-1 downto 0) of logic15_t;

    type state_t is (IDLE, TRANSMIT, TRANSMIT_FINISH);

    pure function total_rows (config : vnir_config_t) return integer is
    begin
        return config.window_red.hi - config.window_red.lo +
                config.window_blue.hi - config.window_blue.lo +
                config.window_nir.hi - config.window_nir.lo;
    end;

    procedure reg_insert_int16 (
        constant i16         : in    integer;
        constant spi_address : in    integer;
        signal   reg         : inout reg_t;
        constant reg_address : in    integer
    ) is
        variable l16 : std_logic_vector(15 downto 0);
    begin
        -- TODO: make sure this works properly with endian-ness, bit order, etc.
        l16 := std_logic_vector(to_unsigned(i16, 16));
        reg(reg_address)     <= std_logic_vector(to_unsigned(spi_address,     7)) & l16(7 downto 0);
        reg(reg_address + 1) <= std_logic_vector(to_unsigned(spi_address + 1, 7)) & l16(15 downto 8);
    end procedure reg_insert_int16;

    procedure translate_config_to_reg (
        signal config   : in    vnir_config_t;
        signal reg_data : inout reg_t
    ) is
        constant window_total_size_address : integer := 1;
        constant window_red_start_address  : integer := 3;
        constant window_blue_start_address : integer := 5;
        constant window_nir_start_address  : integer := 7;
        constant window_red_size_address   : integer := 19;
        constant window_blue_size_address  : integer := 21;
        constant window_nir_size_address   : integer := 23;
    begin
        reg_insert_int16(total_rows(config), window_total_size_address, reg_data, 0);
        reg_insert_int16(config.window_red.lo, window_red_start_address, reg_data, 2);
        reg_insert_int16(config.window_blue.lo, window_blue_start_address, reg_data, 4);
        reg_insert_int16(config.window_nir.lo, window_nir_start_address, reg_data, 6);
        reg_insert_int16(config.window_red.hi - config.window_red.lo, window_red_size_address, reg_data, 8);
        reg_insert_int16(config.window_blue.hi - config.window_blue.lo, window_blue_size_address, reg_data, 10);
        reg_insert_int16(config.window_nir.hi - config.window_nir.lo, window_nir_size_address, reg_data, 12);
        assert reg_data_size = 14;
    end procedure translate_config_to_reg;

    signal spi_enable : std_logic;
    signal spi_cont : std_logic;
    signal spi_tx_data : std_logic_vector(15 downto 0);
    signal spi_busy : std_logic;
    signal spi_ss_n : std_logic_vector(0 downto 0);

    signal state : state_t;
    signal reg_data : reg_t;
begin

    main_process : process (clock)
        variable i : integer;
        variable spi_busy_prev : std_logic;
	begin
		if rising_edge(clock) then
            config_done <= '0';
            spi_enable <= '0';
            spi_cont <= '0';
            
            if (reset_n = '0') then
				state <= IDLE;
            else
				case state is
                when IDLE =>
                    if start_config = '1' then
                        state <= TRANSMIT;
                        translate_config_to_reg(config, reg_data);
                        i := 0;
                        spi_tx_data <= '1' & reg_data(i);
                    end if;
                when TRANSMIT =>
                    spi_enable <= '1';
                    spi_cont <= '1';
                    if (spi_busy = '1' and spi_busy_prev = '0') then
                        if (i = reg_data_size - 1) then
                            state <= TRANSMIT_FINISH;
                        else
                            i := i + 1;
                            spi_tx_data <= '1' & reg_data(i);
                        end if;
                    end if;
                when TRANSMIT_FINISH =>
                    if spi_busy = '0' then
                        state <= IDLE;
                        config_done <= '1';
                    end if;
                end case;
            end if;

            spi_busy_prev := spi_busy;
        end if;
    end process main_process;

    -- Invert ss line to make is active-high as per the CMV2000 datasheet
    spi_out.slave_select <= not spi_ss_n(0);
    
    spi_controller : spi_master generic map(
        slaves		=>	1,
        d_width		=>	16
    ) port map(
        clock		=>	clock,
        reset_n		=>	reset_n,
        enable		=>	spi_enable,
        cpol		=>	'0',		-- chosen based on CMV2000 datasheet
        cpha		=>	'0',		-- ^
        cont		=>	spi_cont,
        clk_div		=>	0,
        addr		=>	0,
        tx_data		=>	spi_tx_data,
        miso		=>	spi_in.data,
        sclk		=>	spi_out.clock,
        ss_n		=>	spi_ss_n,
        mosi		=>	spi_out.data,
        busy		=>	spi_busy,
        rx_data		=>	open
    );

end rtl;
