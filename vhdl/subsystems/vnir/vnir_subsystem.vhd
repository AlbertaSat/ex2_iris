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

use work.vnir_base.all;
use work.row_collector_pkg;
use work.sensor_configurer_pkg;
use work.sensor_configurer_defaults;
use work.frame_requester_pkg;
use work.vnir;


entity vnir_subsystem is
generic (
    CLOCKS_PER_SEC      : integer := 50000000;

    POWER_ON_DELAY_us   : integer := sensor_configurer_defaults.POWER_ON_DELAY_us;
    CLOCK_ON_DELAY_us   : integer := sensor_configurer_defaults.CLOCK_ON_DELAY_us;
    RESET_OFF_DELAY_us  : integer := sensor_configurer_defaults.RESET_OFF_DELAY_us;
    SPI_SETTLE_us       : integer := sensor_configurer_defaults.SPI_SETTLE_us
);
port (
    clock               : in std_logic;
    reset_n             : in std_logic;

    sensor_clock        : in std_logic;
    sensor_clock_locked : in std_logic;
    sensor_power        : out std_logic;
    sensor_clock_enable : out std_logic;
    sensor_reset_n      : out std_logic;

    config              : in vnir.config_t;
    start_config        : in std_logic;
    config_done         : out std_logic;
    
    image_config        : in vnir.image_config_t;
    start_image_config  : in std_logic;
    image_config_done   : out std_logic;
    num_rows            : out integer;
    
    do_imaging          : in std_logic;
    imaging_done        : out std_logic;

    row                 : out vnir.row_t;
    row_available       : out vnir.row_type_t;
    
    spi_out             : out spi_from_master_t;
    spi_in              : in spi_to_master_t;
    
    frame_request       : out std_logic;
    exposure_start      : out std_logic;
    lvds                : in vnir.lvds_t
);
end entity vnir_subsystem;


architecture rtl of vnir_subsystem is

    component delay_until is
    port (
        clock           : in std_logic;
        reset_n         : in std_logic;
        condition       : in std_logic;
        start           : in std_logic;
        done            : out std_logic
    );
    end component delay_until;

    component idivide is
    port (
        clock   : in std_logic;
        reset_n : in std_logic;
        n       : in integer;
        d       : in integer;
        q       : out integer;
        start   : in std_logic;
        done    : out std_logic
    );
    end component idivide;
        

    component sensor_configurer is
    generic (
        FRAGMENT_WIDTH      : integer;
        PIXEL_BITS          : integer;
        N_WINDOWS           : integer;
        CLOCKS_PER_SEC      : integer;
        POWER_ON_DELAY_us   : integer;
        CLOCK_ON_DELAY_us   : integer;
        reset_off_delay_us  : integer;
        SPI_SETTLE_us       : integer
    );
    port (	
        clock               : in std_logic;
        reset_n             : in std_logic;
        config              : in sensor_configurer_pkg.config_t;
        start_config        : in std_logic;
        config_done         : out std_logic;
        spi_out             : out spi_from_master_t;
        spi_in              : in spi_to_master_t;
        sensor_power        : out std_logic;
        sensor_clock_enable : out std_logic;
        sensor_reset_n      : out std_logic
    );
    end component sensor_configurer;

    component lvds_decoder is
    generic (
        FRAGMENT_WIDTH      : integer;
        PIXEL_BITS          : integer
    );
    port (
        clock               : in std_logic;
        reset_n             : in std_logic;
        start_align         : in std_logic;
        align_done          : out std_logic;
        lvds_clock          : in std_logic;
        lvds_control        : in std_logic;
        lvds_data           : in std_logic_vector;
        fragment            : out pixel_vector_t;
        fragment_control    : out control_t;
        fragment_available  : out std_logic
    );
    end component lvds_decoder;

    component frame_requester is
    generic (
        FRAGMENT_WIDTH      : integer;
        CLOCKS_PER_SEC      : integer
    );
    port (
        clock               : in std_logic;
        reset_n             : in std_logic;
        config              : in frame_requester_pkg.config_t;
        start_config        : in std_logic;
        config_done         : out std_logic;
        do_imaging          : in std_logic;
        imaging_done        : out std_logic;
        sensor_clock        : in std_logic;
        frame_request       : out std_logic;
        exposure_start      : out std_logic
    );
    end component frame_requester;

    component row_collector is
    generic (
        ROW_WIDTH           : integer;
        FRAGMENT_WIDTH      : integer;
        PIXEL_BITS          : integer;
        ROW_PIXEL_BITS      : integer;
        N_WINDOWS           : integer range 1 to row_collector_pkg.MAX_N_WINDOWS
    );
    port (
        clock               : in std_logic;
        reset_n             : in std_logic;
        config              : in row_collector_pkg.config_t;
        read_config         : in std_logic;
        start               : in std_logic;
        done                : out std_logic;
        fragment            : in pixel_vector_t;
        fragment_available  : in std_logic;
        row                 : out pixel_vector_t;
        row_window          : out integer
    );
    end component row_collector;

    signal config_reg       : vnir.config_t;
    signal image_config_reg : vnir.image_config_t;

    signal imaging_done_s : std_logic;

    signal start_calc_image_length : std_logic;
    signal calc_image_length_done  : std_logic;

    signal start_frame_requester_config : std_logic;
    signal frame_requester_config       : frame_requester_pkg.config_t;
    signal frame_requester_config_done  : std_logic;

    signal start_sensor_config      : std_logic;
    signal sensor_configurer_config : sensor_configurer_pkg.config_t;
    signal sensor_config_done       : std_logic;

    signal start_align : std_logic;
    signal align_done  : std_logic;
    
    signal start_locking : std_logic;
    signal locking_done  : std_logic;

    signal row_collector_config : row_collector_pkg.config_t;

    signal fragment                 : pixel_vector_t(vnir.FRAGMENT_WIDTH-1 downto 0)(vnir.PIXEL_BITS-1 downto 0);
    signal fragment_control         : control_t;
    signal fragment_available       : std_logic;
    
    signal image_length : integer;
    signal num_frames  : integer;

    signal row_window       : integer;

begin

    fsm : process
        type state_t is (RESET, PRE_CONFIG, CONFIGURING, PRE_IMAGE_CONFIG, IMAGE_CONFIGURING, IDLE, IMAGING);
        variable state : state_t;
    begin
        wait until rising_edge(clock);
        
        start_locking <= '0';
        start_calc_image_length <= '0';
        config_done <= '0';
        image_config_done <= '0';

        if reset_n = '0' then
            state := RESET;
        end if;

        case state is
        when RESET =>
            state := PRE_CONFIG;
        when PRE_CONFIG =>
            assert start_image_config = '0';
            assert do_imaging = '0';
            if start_config = '1' then
                config_reg <= config;
                start_locking <= '1';
                state := CONFIGURING;
            end if;
        when CONFIGURING =>
            assert start_config = '0';
            assert start_image_config = '0';
            assert do_imaging = '0';
            if align_done = '1' then
                config_done <= '1';
                state := PRE_IMAGE_CONFIG;
            end if;
        when PRE_IMAGE_CONFIG =>
            assert start_config = '0';
            assert do_imaging = '0';
            if start_image_config = '1' then
                image_config_reg <= image_config;
                start_calc_image_length <= '1';
                state := IMAGE_CONFIGURING;
            end if;
        when IMAGE_CONFIGURING =>
            assert start_config = '0';
            assert start_image_config = '0';
            assert do_imaging = '0';
            if frame_requester_config_done = '1' then
                image_config_done <= '1';
                state := IDLE;
            end if;
        when IDLE =>
            assert (start_config = '0' and start_image_config = '0' and do_imaging = '0') or
                   (start_config = '1' and start_image_config = '0' and do_imaging = '0') or
                   (start_config = '0' and start_image_config = '1' and do_imaging = '0') or
                   (start_config = '0' and start_image_config = '0' and do_imaging = '1');
                   
            if start_config = '1' then
                config_reg <= config;
                start_locking <= '1';
                state := CONFIGURING;
            end if;
            if start_image_config = '1' then
                image_config_reg <= image_config;
                start_calc_image_length <= '1';
                state := IMAGE_CONFIGURING;
            end if;
            if do_imaging = '1' then
                -- TODO: might want to start the frame_requester here instead of it starting independently
                state := IMAGING;
            end if;
        when IMAGING =>
            assert start_config = '0';
            assert start_image_config = '0';
            assert do_imaging = '0';
            if imaging_done_s = '1' then -- TODO: might want to make sure row_collator is finished
                state := IDLE; 
            end if;
        end case;
    end process fsm;

    start_frame_requester_config <= calc_image_length_done;
    start_sensor_config <= locking_done;
    start_align <= sensor_config_done;

    delay_until_locked : delay_until port map (
        clock => clock,
        reset_n => reset_n,
        condition => sensor_clock_locked,
        start => start_locking,
        done => locking_done
    );

    sensor_configurer_component : sensor_configurer generic map (
        FRAGMENT_WIDTH => vnir.FRAGMENT_WIDTH,
        PIXEL_BITS => vnir.PIXEL_BITS,
        N_WINDOWS => vnir.N_WINDOWS,
        CLOCKS_PER_SEC => CLOCKS_PER_SEC,
        POWER_ON_DELAY_us => POWER_ON_DELAY_us,
        CLOCK_ON_DELAY_us => CLOCK_ON_DELAY_us,
        reset_off_delay_us => RESET_OFF_DELAY_us,
        SPI_SETTLE_us => SPI_SETTLE_us
    ) port map (
        clock => clock,
        reset_n => reset_n,
        config => sensor_configurer_config,
        start_config => start_sensor_config,
        config_done => sensor_config_done,
        spi_out => spi_out,
        spi_in => spi_in,
        sensor_power => sensor_power,
        sensor_clock_enable => sensor_clock_enable,
        sensor_reset_n => sensor_reset_n
    );
    
    frame_requester_component : frame_requester generic map (
        FRAGMENT_WIDTH => vnir.FRAGMENT_WIDTH,
        CLOCKS_PER_SEC => CLOCKS_PER_SEC
    ) port map (
        clock => clock,
        reset_n => reset_n,
        config => frame_requester_config,
        start_config => start_frame_requester_config,
        config_done => frame_requester_config_done,
        do_imaging => do_imaging,
        sensor_clock => sensor_clock,
        frame_request => frame_request,
        exposure_start => exposure_start
    );

    lvds_decoder_component : lvds_decoder generic map (
        FRAGMENT_WIDTH => vnir.FRAGMENT_WIDTH,
        PIXEL_BITS => vnir.PIXEL_BITS
    ) port map (
        clock => clock,
        reset_n => reset_n,
        start_align => start_align,
        align_done => align_done,
        lvds_clock => lvds.clock,
        lvds_control => lvds.control,
        lvds_data => lvds.data,
        fragment => fragment,
        fragment_control => fragment_control,
        fragment_available => fragment_available
    );

    row_collector_component : row_collector generic map (
        ROW_WIDTH => vnir.ROW_WIDTH,
        FRAGMENT_WIDTH => vnir.FRAGMENT_WIDTH,
        PIXEL_BITS => vnir.PIXEL_BITS,
        ROW_PIXEL_BITS => vnir.ROW_PIXEL_BITS,
        N_WINDOWS => vnir.N_WINDOWS
    ) port map (
        clock => clock,
        reset_n => reset_n,
        config => row_collector_config,
        read_config => start_frame_requester_config,
        start => do_imaging,
        done => imaging_done_s,
        fragment => fragment,
        fragment_available => fragment_available and fragment_control.dval,
        row => row,
        row_window => row_window
    );
    imaging_done <= imaging_done_s;

    calc_image_length : idivide port map (
        clock => clock,
        reset_n => reset_n,
        n => image_config_reg.duration * image_config_reg.fps,
        d => 1000,
        q => image_length,
        start => start_calc_image_length,
        done => calc_image_length_done
    );

    num_frames <= image_length + config_reg.window_blue.hi; -- TODO: move into row_collector
    
    sensor_configurer_config <= (
        flip => config_reg.flip,
        calibration => config_reg.calibration,
        windows => (
            0 => config_reg.window_red,
            1 => config_reg.window_nir,
            2 => config_reg.window_blue,
            others => (others => 0)
        )
    );
    frame_requester_config <= (
        num_frames => num_frames,
        fps => image_config_reg.fps,
        exposure_time => image_config_reg.exposure_time
    );
    row_collector_config <= (
        image_length => image_length,
        windows => (
            0 => config_reg.window_red,
            1 => config_reg.window_nir,
            2 => config_reg.window_blue,
            others => (others => 0)
        )
    );

    row_available <= vnir.ROW_RED when row_window = 0 else
                     vnir.ROW_NIR when row_window = 1 else
                     vnir.ROW_BLUE when row_window = 2 else
                     vnir.ROW_NONE;
    num_rows <= image_length;

end architecture rtl;