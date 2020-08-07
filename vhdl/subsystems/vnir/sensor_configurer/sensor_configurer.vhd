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

use work.vnir_common.all;
use work.spi_types.all;
use work.logic_types.all;
use work.sensor_configurer_pkg.all;
use work.sensor_configurer_defaults;

entity sensor_configurer is
generic (
    CLOCKS_PER_SEC      : integer;

    POWER_ON_DELAY_us   : integer := sensor_configurer_defaults.POWER_ON_DELAY_us;
    CLOCK_ON_DELAY_us   : integer := sensor_configurer_defaults.CLOCK_ON_DELAY_us;
    RESET_OFF_DELAY_us  : integer := sensor_configurer_defaults.RESET_OFF_DELAY_us;
    SPI_SETTLE_us       : integer := sensor_configurer_defaults.SPI_SETTLE_us
);
port (
    clock               : in std_logic;
    reset_n             : in std_logic;

    config              : in config_t;
    start_config        : in std_logic;
    config_done         : out std_logic;
    
    spi_out             : out spi_from_master_t;
    spi_in              : in spi_to_master_t;
    
    sensor_power        : out std_logic;
    sensor_clock_enable : out std_logic;
    sensor_reset_n      : out std_logic
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
        tx_data : in     logic16_t;  
        miso    : in     std_logic;                             
        sclk    : buffer std_logic;                             
        ss_n    : buffer std_logic_vector(0 downto 0);   
        mosi    : out    std_logic;                             
        busy    : out    std_logic;                             
        rx_data : out    logic16_t
    ); 
    end component;

    component timer is
    generic (
        CLOCKS_PER_SEC  : integer;
        DELAY_us        : integer
    );
    port (
        clock   : in std_logic;
        reset_n : in std_logic;
        start   : in std_logic;
        done    : out std_logic
    );
    end component timer;

    signal spi_enable : std_logic;
    signal spi_cont : std_logic;
    signal spi_tx_data : std_logic_vector(15 downto 0);
    signal spi_busy : std_logic;
    signal spi_ss_n : std_logic;

    type timer_t is record
        start : std_logic;
        done : std_logic;
    end record timer_t;

    signal power_on_timer   : timer_t;
    signal clock_on_timer   : timer_t;
    signal reset_off_timer  : timer_t;
    signal spi_settle_timer : timer_t;

begin

    main_process : process
        type state_t is (RESET, OFF, IDLE, CONFIG_POWER_ON, CONFIG_CLOCK_ON, CONFIG_RESET_OFF,
                         CONFIG_TRANSMIT, CONFIG_TRANSMIT_FINISH, CONFIG_SPI_SETTLE);
        variable state : state_t;

        variable i : integer;
        variable spi_busy_prev : std_logic;

        constant N_SPI_INSTRUCTIONS : integer := 39;  -- Length of all_instructions() output
        variable spi_instructions : logic16_vector_t(N_SPI_INSTRUCTIONS-1 downto 0);
    begin
        wait until rising_edge(clock);

        power_on_timer.start <= '0';
        clock_on_timer.start <= '0';
        reset_off_timer.start <= '0';
        spi_settle_timer.start <= '0';
        config_done <= '0';
        spi_enable <= '0';
        spi_cont <= '0';

        if (reset_n = '0') then
            state := RESET;
        end if;

        case state is
        when RESET =>
            state := OFF;
            sensor_power <= '0';
            sensor_reset_n <= '0';
            sensor_clock_enable <= '0';
        when OFF =>
            if start_config = '1' then
                spi_instructions := all_instructions(config);
                power_on_timer.start <= '1';
                state := CONFIG_POWER_ON;
            end if;
        when CONFIG_POWER_ON =>
            sensor_power <= '1';
            if power_on_timer.done = '1' then
                clock_on_timer.start <= '1';
                state := CONFIG_CLOCK_ON;
            end if;
        when CONFIG_CLOCK_ON =>
            sensor_clock_enable <= '1';
            if clock_on_timer.done = '1' then
                reset_off_timer.start <= '1';
                state := CONFIG_RESET_OFF;
            end if;
        when IDLE =>
            if start_config = '1' then
                spi_instructions := all_instructions(config);
                sensor_reset_n <= '0';
                reset_off_timer.start <= '1';
                state := CONFIG_RESET_OFF;
            end if;
        when CONFIG_RESET_OFF =>
            sensor_reset_n <= '1';
            if reset_off_timer.done = '1' then
                i := 0;
                spi_tx_data <= spi_instructions(i);
                state := CONFIG_TRANSMIT;
            end if;
        when CONFIG_TRANSMIT =>
            spi_enable <= '1';
            spi_cont <= '1';
            if (spi_busy = '1' and spi_busy_prev = '0') then
                if (i = N_SPI_INSTRUCTIONS - 1) then
                    state := CONFIG_TRANSMIT_FINISH;
                else
                    i := i + 1;
                    spi_tx_data <= spi_instructions(i);
                end if;
            end if;
        when CONFIG_TRANSMIT_FINISH =>
            if spi_busy = '0' then
                spi_settle_timer.start <= '1';
                state := CONFIG_SPI_SETTLE;
            end if;
        when CONFIG_SPI_SETTLE =>
            if spi_settle_timer.done = '1' then
                config_done <= '1';
                state := IDLE;
            end if;
        end case;
        
        spi_busy_prev := spi_busy;

    end process main_process;

    -- Invert ss line to make it active-high as per the CMV2000 datasheet
    spi_out.slave_select <= not spi_ss_n;
    
    spi_controller : spi_master generic map(
        slaves      =>	1,
        d_width     =>	16
    ) port map(
        clock       =>	clock,
        reset_n     =>	reset_n,
        enable      =>	spi_enable,
        cpol        =>	'0',        -- chosen based on CMV2000 datasheet
        cpha        =>	'0',        -- ^
        cont        =>	spi_cont,
        clk_div     =>	0,
        addr        =>	0,
        tx_data     =>	spi_tx_data,
        miso        =>	spi_in.data,
        sclk        =>	spi_out.clock,
        ss_n(0)     =>	spi_ss_n,
        mosi        =>	spi_out.data,
        busy        =>	spi_busy,
        rx_data     =>	open
    );

    power_on_timer_cmp : timer generic map (
        CLOCKS_PER_SEC => CLOCKS_PER_SEC,
        DELAY_us => POWER_ON_DELAY_us
    ) port map (
        clock => clock,
        reset_n => reset_n,
        start => power_on_timer.start,
        done => power_on_timer.done
    );

    clock_on_timer_cmp : timer generic map (
        CLOCKS_PER_SEC => CLOCKS_PER_SEC,
        DELAY_us => CLOCK_ON_DELAY_us
    ) port map (
        clock => clock,
        reset_n => reset_n,
        start => clock_on_timer.start,
        done => clock_on_timer.done
    );

    reset_off_timer_cmp : timer generic map (
        CLOCKS_PER_SEC => CLOCKS_PER_SEC,
        DELAY_us => RESET_OFF_DELAY_us
    ) port map (
        clock => clock,
        reset_n => reset_n,
        start => reset_off_timer.start,
        done => reset_off_timer.done
    );

    spi_settle_timer_cmp : timer generic map (
        CLOCKS_PER_SEC => CLOCKS_PER_SEC,
        DELAY_us => SPI_SETTLE_us
    ) port map (
        clock => clock,
        reset_n => reset_n,
        start => spi_settle_timer.start,
        done => spi_settle_timer.done
    );


end rtl;


