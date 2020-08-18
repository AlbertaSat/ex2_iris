-- qsys_interface_tb.vhd
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

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--use work.avalonmm_types.all;
--use work.sdram_types.all;
--use work.vnir_types.all;
--use work.swir_types.all;
--use work.fpga_types.all;

entity qsys_interface_tb is
-- Port ( );
end entity qsys_interface_tb;

architecture rtl of qsys_interface_tb is

component qsys_interface
Port(
    reset_n                : in  std_logic                     := '0';                   --        reset.reset_n
    clock                  : in  std_logic                     := '0';                   --        clock.clk
    -- avalon MM interface
    avalon_slave_write_n   : in  std_logic                     := '0';                   -- avalon_slave.write_n
    avalon_slave_writedata : in  std_logic_vector(31 downto 0) := (others => '0');       --             .writedata
    conduit_end_avalon     : out std_logic_vector(31 downto 0)                    --  conduit_end.new_signal
    );
end component;

component avalon_sim is
	port (
		reset_n                : in  std_logic                     := '1';
        clock                  : in  std_logic                     := '0'
    );                                       
end component avalon_sim;

signal reset_n, clock, avalon_slave_write_n: std_logic := '0';
signal avalon_slave_writedata: std_logic_vector(31 downto 0) := (others => '0');
signal conduit_end_avalon, data_conduit: std_logic_vector(31 downto 0) := (others => '0');

type flip_state is
	(FLIP_NONE, FLIP_X, FLIP_Y, FLIP_XY);

signal vnir_config_window_blue_lo: integer;
signal vnir_config_window_blue_hi: integer;
signal vnir_config_window_red_lo: integer;
signal vnir_config_window_red_hi: integer;
signal vnir_config_window_nir_lo: integer;
signal vnir_config_window_nir_hi: integer;

signal vnir_config_calibration_vramp1: integer;
signal vnir_config_calibration_vramp2: integer;
signal vnir_config_calibration_adc_gain: integer;
signal vnir_config_calibration_offset: integer;
signal vnir_start_config: std_logic:= '0';

signal vnir_config_flip: flip_state;

signal sdram_config_out_memory_base: std_logic_vector(31 downto 0);
signal sdram_config_out_memory_bounds: std_logic_vector(31 downto 0);
signal sdram_start_config: std_logic:= '0';

signal vnir_image_config_duration: integer;
signal vnir_image_exposure_time: integer;
signal vnir_image_fps: integer;
signal vnir_start_image_config: std_logic:= '0';

signal vnir_do_imaging: std_logic:= '0';

signal config_confirmed: std_logic:= '0';

signal image_config_confirmed: std_logic:= '0';

signal unexpected_identifier: std_logic:= '0';

constant clock_period: time:= 10 ns;

begin

    qsys_interface_port_map: qsys_interface 
    port map(
    reset_n => reset_n,
    clock => clock,
    avalon_slave_write_n => avalon_slave_write_n,
    avalon_slave_writedata => avalon_slave_writedata,
    conduit_end_avalon => conduit_end_avalon
    );

    avalon_sim_port_map: avalon_sim
    port map(
    reset_n => reset_n,
    clock => clock
    );

    tb_clock: process
    begin
        clock <= '0';
        wait for clock_period/2;
        clock <= '1';
        wait for clock_period/2;
    end process tb_clock;

    -- TODO: 
    --     x ADD ANY EXPECTED DATA INSIDE THE WRITEDATA VECTORS
    --     x TEST WITH RESET_N AS WELL

    stimulus: process
    begin
    
    -- vnir_config.window_blue.lo/hi
    wait for 50 ns; -- multiple clock cycles, like in real time
    avalon_slave_write_n <='1';
    avalon_slave_writedata <= "00000000000000000000000000000001"; 
    wait for 50 ns; -- multiple clock cycles, like in real time
    avalon_slave_write_n <='0';

    -- vnir_config.window_red.lo/hi
    wait for 50 ns;
    avalon_slave_write_n <='1';
    avalon_slave_writedata <= "00000000000000000000000000000010"; 
    wait for 50 ns;
    avalon_slave_write_n <='0';

    -- vnir_config.window_nir.lo/hi
    wait for 50 ns;
    avalon_slave_write_n <='1';
    avalon_slave_writedata <= "00000000000000000000000000000011"; 
    wait for 50 ns;
    avalon_slave_write_n <='0';

    -- vnir_config.calibration.vramp1/vramp2/adc_gain w/ FLIP_NONE
    wait for 50 ns;
    avalon_slave_write_n <='1';
    avalon_slave_writedata <= "00000000000000000000000000000100"; 
    wait for 50 ns;
    avalon_slave_write_n <='0';

    -- vnir_config.calibration.vramp1/vramp2/adc_gain w/ FLIP_X
    wait for 50 ns;
    avalon_slave_write_n <='1';
    avalon_slave_writedata <= "01000000000000000000000000000100"; 
    wait for 50 ns;
    avalon_slave_write_n <='0';

    -- vnir_config.calibration.vramp1/vramp2/adc_gain w/ FLIP_Y
    wait for 50 ns;
    avalon_slave_write_n <='1';
    avalon_slave_writedata <= "10000000000000000000000000000100"; 
    wait for 50 ns;
    avalon_slave_write_n <='0';

    -- vnir_config.calibration.vramp1/vramp2/adc_gain w/ FLIP_XY
    wait for 50 ns;
    avalon_slave_write_n <='1';
    avalon_slave_writedata <= "11000000000000000000000000000100"; 
    wait for 50 ns;
    avalon_slave_write_n <='0';

    -- vnir_config.calibration.offset (vnir_start_config at ...writedata(22))
    wait for 50 ns;
    avalon_slave_write_n <='1';
    avalon_slave_writedata <= "00000000010000000000000000000101"; 
    wait for 50 ns;
    avalon_slave_write_n <='0';

    -- sdram_config_out.memory_base part 1
    wait for 50 ns;
    avalon_slave_write_n <='1';
    avalon_slave_writedata <= "00000000000000000000000000000110"; 
    wait for 50 ns;
    avalon_slave_write_n <='0';

    -- sdram_config_out.memory_base part 2 and bounds part 1
    wait for 50 ns;
    avalon_slave_write_n <='1';
    avalon_slave_writedata <= "00000000000000000000000000000111"; 
    wait for 50 ns;
    avalon_slave_write_n <='0';

    -- sdram_config_out.memory_bounds part 2 (sdram_start_config at ...writedata(16))
    wait for 50 ns;
    avalon_slave_write_n <='1';
    avalon_slave_writedata <= "00000000000000010000000000001000"; 
    wait for 50 ns;
    avalon_slave_write_n <='0';

    -- vnir_image_config.duration/exposure_time
    wait for 50 ns;
    avalon_slave_write_n <='1';
    avalon_slave_writedata <= "00000000000000000000000000001001"; 
    wait for 50 ns;
    avalon_slave_write_n <='0';

    -- vnir_image_config.fps (vnir_start_image_config at ...writedata(18))
    wait for 50 ns;
    avalon_slave_write_n <='1';
    avalon_slave_writedata <= "00000000000001000000000000001010"; 
    wait for 50 ns;
    avalon_slave_write_n <='0';

    -- init_timestamp
    wait for 50 ns;
    avalon_slave_write_n <='1';
    avalon_slave_writedata <= "00000000000000000000000000010000"; 
    wait for 50 ns;
    avalon_slave_write_n <='0';

    -- vnir_do_imaging
    wait for 50 ns;
    avalon_slave_write_n <='1';
    avalon_slave_writedata <= "00000000000000000000000000010001"; 
    wait for 50 ns;
    avalon_slave_write_n <='0';

    -- config_confirmed
    wait for 50 ns;
    avalon_slave_write_n <='1';
    avalon_slave_writedata <= "00000000000000000000000000010010"; 
    wait for 50 ns;
    avalon_slave_write_n <='0';

    -- image_config_confirmed
    wait for 50 ns;
    avalon_slave_write_n <='1';
    avalon_slave_writedata <= "00000000000000000000000000010011"; 
    wait for 50 ns;
    avalon_slave_write_n <='0';

    -- intentional error (~~~~ unexpected_identifier ~~~~)
    wait for 50 ns;
    avalon_slave_write_n <='1';
    avalon_slave_writedata <= "00000000000000000000000000000000"; 
    wait for 50 ns;
    avalon_slave_write_n <='0';

    end process stimulus;


end rtl;