-- Copyright (C) 2017  Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License 
-- Subscription Agreement, the Intel Quartus Prime License Agreement,
-- the Intel MegaCore Function License Agreement, or other 
-- applicable license agreement, including, without limitation, 
-- that your use is for the sole purpose of programming logic 
-- devices manufactured by Intel and sold by Intel or its 
-- authorized distributors.  Please refer to the applicable 
-- agreement for further details.

-- VENDOR "Altera"
-- PROGRAM "Quartus Prime"
-- VERSION "Version 17.0.0 Build 595 04/25/2017 SJ Standard Edition"

-- DATE "08/17/2020 21:17:34"

-- 
-- Device: Altera 5CSEBA6U23I7DK Package UFBGA672
-- 

-- 
-- This VHDL file should be used for ModelSim-Altera (VHDL) only
-- 

LIBRARY ALTERA_LNSIM;
LIBRARY CYCLONEV;
LIBRARY IEEE;
USE ALTERA_LNSIM.ALTERA_LNSIM_COMPONENTS.ALL;
USE CYCLONEV.CYCLONEV_COMPONENTS.ALL;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY 	qsys_interface IS
    PORT (
	avalon_slave_write_n : IN std_logic;
	avalon_slave_writedata : IN std_logic_vector(31 DOWNTO 0);
	conduit_end_avalon : BUFFER std_logic_vector(31 DOWNTO 0);
	reset_n : IN std_logic;
	clock : IN std_logic
	);
END qsys_interface;

-- Design Ports Information
-- avalon_slave_write_n	=>  Location: PIN_AE9,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[0]	=>  Location: PIN_Y24,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[1]	=>  Location: PIN_AG11,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[2]	=>  Location: PIN_Y18,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[3]	=>  Location: PIN_AE26,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[4]	=>  Location: PIN_AB26,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[5]	=>  Location: PIN_AA20,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[6]	=>  Location: PIN_AF9,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[7]	=>  Location: PIN_AC4,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[8]	=>  Location: PIN_AG9,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[9]	=>  Location: PIN_W15,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[10]	=>  Location: PIN_AD26,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[11]	=>  Location: PIN_T11,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[12]	=>  Location: PIN_AH14,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[13]	=>  Location: PIN_AA24,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[14]	=>  Location: PIN_AF10,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[15]	=>  Location: PIN_V15,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[16]	=>  Location: PIN_AG10,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[17]	=>  Location: PIN_AC22,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[18]	=>  Location: PIN_T8,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[19]	=>  Location: PIN_AH24,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[20]	=>  Location: PIN_AF6,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[21]	=>  Location: PIN_T12,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[22]	=>  Location: PIN_AG6,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[23]	=>  Location: PIN_AD10,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[24]	=>  Location: PIN_AE24,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[25]	=>  Location: PIN_AE19,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[26]	=>  Location: PIN_AG26,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[27]	=>  Location: PIN_AF25,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[28]	=>  Location: PIN_Y8,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[29]	=>  Location: PIN_AG25,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[30]	=>  Location: PIN_AG19,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- conduit_end_avalon[31]	=>  Location: PIN_AG5,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- reset_n	=>  Location: PIN_V11,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- clock	=>  Location: PIN_AE4,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[0]	=>  Location: PIN_W24,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[1]	=>  Location: PIN_AA13,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[2]	=>  Location: PIN_Y17,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[3]	=>  Location: PIN_Y16,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[4]	=>  Location: PIN_W20,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[5]	=>  Location: PIN_Y19,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[6]	=>  Location: PIN_AD11,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[7]	=>  Location: PIN_AD4,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[8]	=>  Location: PIN_AH8,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[9]	=>  Location: PIN_AB23,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[10]	=>  Location: PIN_AE25,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[11]	=>  Location: PIN_AE7,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[12]	=>  Location: PIN_AE17,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[13]	=>  Location: PIN_V16,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[14]	=>  Location: PIN_AF11,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[15]	=>  Location: PIN_AA23,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[16]	=>  Location: PIN_AF15,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[17]	=>  Location: PIN_AH26,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[18]	=>  Location: PIN_AB4,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[19]	=>  Location: PIN_AG24,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[20]	=>  Location: PIN_W11,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[21]	=>  Location: PIN_AH2,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[22]	=>  Location: PIN_AF7,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[23]	=>  Location: PIN_AF4,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[24]	=>  Location: PIN_AC23,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[25]	=>  Location: PIN_AF18,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[26]	=>  Location: PIN_AE23,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[27]	=>  Location: PIN_AH27,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[28]	=>  Location: PIN_W8,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[29]	=>  Location: PIN_AG28,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[30]	=>  Location: PIN_AH19,	 I/O Standard: 2.5 V,	 Current Strength: Default
-- avalon_slave_writedata[31]	=>  Location: PIN_AH4,	 I/O Standard: 2.5 V,	 Current Strength: Default


ARCHITECTURE structure OF qsys_interface IS
SIGNAL gnd : std_logic := '0';
SIGNAL vcc : std_logic := '1';
SIGNAL unknown : std_logic := 'X';
SIGNAL devoe : std_logic := '1';
SIGNAL devclrn : std_logic := '1';
SIGNAL devpor : std_logic := '1';
SIGNAL ww_devoe : std_logic;
SIGNAL ww_devclrn : std_logic;
SIGNAL ww_devpor : std_logic;
SIGNAL ww_avalon_slave_write_n : std_logic;
SIGNAL ww_avalon_slave_writedata : std_logic_vector(31 DOWNTO 0);
SIGNAL ww_conduit_end_avalon : std_logic_vector(31 DOWNTO 0);
SIGNAL ww_reset_n : std_logic;
SIGNAL ww_clock : std_logic;
SIGNAL \avalon_slave_write_n~input_o\ : std_logic;
SIGNAL \reset_n~input_o\ : std_logic;
SIGNAL \clock~input_o\ : std_logic;
SIGNAL \~QUARTUS_CREATED_GND~I_combout\ : std_logic;
SIGNAL \avalon_slave_writedata[0]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[1]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[2]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[3]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[4]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[5]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[6]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[7]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[8]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[9]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[10]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[11]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[12]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[13]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[14]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[15]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[16]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[17]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[18]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[19]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[20]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[21]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[22]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[23]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[24]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[25]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[26]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[27]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[28]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[29]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[30]~input_o\ : std_logic;
SIGNAL \avalon_slave_writedata[31]~input_o\ : std_logic;

BEGIN

ww_avalon_slave_write_n <= avalon_slave_write_n;
ww_avalon_slave_writedata <= avalon_slave_writedata;
conduit_end_avalon <= ww_conduit_end_avalon;
ww_reset_n <= reset_n;
ww_clock <= clock;
ww_devoe <= devoe;
ww_devclrn <= devclrn;
ww_devpor <= devpor;

-- Location: IOOBUF_X89_Y25_N5
\conduit_end_avalon[0]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[0]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(0));

-- Location: IOOBUF_X56_Y0_N36
\conduit_end_avalon[1]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[1]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(1));

-- Location: IOOBUF_X89_Y6_N22
\conduit_end_avalon[2]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[2]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(2));

-- Location: IOOBUF_X89_Y4_N96
\conduit_end_avalon[3]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[3]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(3));

-- Location: IOOBUF_X89_Y23_N39
\conduit_end_avalon[4]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[4]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(4));

-- Location: IOOBUF_X89_Y4_N45
\conduit_end_avalon[5]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[5]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(5));

-- Location: IOOBUF_X30_Y0_N53
\conduit_end_avalon[6]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[6]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(6));

-- Location: IOOBUF_X6_Y0_N36
\conduit_end_avalon[7]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[7]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(7));

-- Location: IOOBUF_X52_Y0_N36
\conduit_end_avalon[8]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[8]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(8));

-- Location: IOOBUF_X89_Y8_N22
\conduit_end_avalon[9]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[9]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(9));

-- Location: IOOBUF_X89_Y6_N56
\conduit_end_avalon[10]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[10]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(10));

-- Location: IOOBUF_X28_Y0_N2
\conduit_end_avalon[11]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[11]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(11));

-- Location: IOOBUF_X62_Y0_N53
\conduit_end_avalon[12]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[12]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(12));

-- Location: IOOBUF_X89_Y9_N39
\conduit_end_avalon[13]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[13]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(13));

-- Location: IOOBUF_X34_Y0_N59
\conduit_end_avalon[14]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[14]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(14));

-- Location: IOOBUF_X89_Y9_N22
\conduit_end_avalon[15]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[15]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(15));

-- Location: IOOBUF_X54_Y0_N36
\conduit_end_avalon[16]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[16]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(16));

-- Location: IOOBUF_X84_Y0_N2
\conduit_end_avalon[17]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[17]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(17));

-- Location: IOOBUF_X4_Y0_N19
\conduit_end_avalon[18]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[18]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(18));

-- Location: IOOBUF_X80_Y0_N53
\conduit_end_avalon[19]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[19]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(19));

-- Location: IOOBUF_X32_Y0_N53
\conduit_end_avalon[20]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[20]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(20));

-- Location: IOOBUF_X36_Y0_N19
\conduit_end_avalon[21]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[21]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(21));

-- Location: IOOBUF_X34_Y0_N93
\conduit_end_avalon[22]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[22]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(22));

-- Location: IOOBUF_X26_Y0_N42
\conduit_end_avalon[23]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[23]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(23));

-- Location: IOOBUF_X82_Y0_N42
\conduit_end_avalon[24]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[24]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(24));

-- Location: IOOBUF_X66_Y0_N42
\conduit_end_avalon[25]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[25]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(25));

-- Location: IOOBUF_X82_Y0_N76
\conduit_end_avalon[26]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[26]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(26));

-- Location: IOOBUF_X86_Y0_N2
\conduit_end_avalon[27]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[27]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(27));

-- Location: IOOBUF_X2_Y0_N59
\conduit_end_avalon[28]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[28]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(28));

-- Location: IOOBUF_X86_Y0_N19
\conduit_end_avalon[29]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[29]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(29));

-- Location: IOOBUF_X70_Y0_N36
\conduit_end_avalon[30]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[30]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(30));

-- Location: IOOBUF_X38_Y0_N36
\conduit_end_avalon[31]~output\ : cyclonev_io_obuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	open_drain_output => "false",
	shift_series_termination_control => "false")
-- pragma translate_on
PORT MAP (
	i => \avalon_slave_writedata[31]~input_o\,
	devoe => ww_devoe,
	o => ww_conduit_end_avalon(31));

-- Location: IOIBUF_X89_Y25_N21
\avalon_slave_writedata[0]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(0),
	o => \avalon_slave_writedata[0]~input_o\);

-- Location: IOIBUF_X56_Y0_N18
\avalon_slave_writedata[1]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(1),
	o => \avalon_slave_writedata[1]~input_o\);

-- Location: IOIBUF_X89_Y6_N4
\avalon_slave_writedata[2]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(2),
	o => \avalon_slave_writedata[2]~input_o\);

-- Location: IOIBUF_X89_Y8_N4
\avalon_slave_writedata[3]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(3),
	o => \avalon_slave_writedata[3]~input_o\);

-- Location: IOIBUF_X89_Y23_N21
\avalon_slave_writedata[4]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(4),
	o => \avalon_slave_writedata[4]~input_o\);

-- Location: IOIBUF_X89_Y4_N61
\avalon_slave_writedata[5]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(5),
	o => \avalon_slave_writedata[5]~input_o\);

-- Location: IOIBUF_X30_Y0_N1
\avalon_slave_writedata[6]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(6),
	o => \avalon_slave_writedata[6]~input_o\);

-- Location: IOIBUF_X6_Y0_N52
\avalon_slave_writedata[7]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(7),
	o => \avalon_slave_writedata[7]~input_o\);

-- Location: IOIBUF_X52_Y0_N52
\avalon_slave_writedata[8]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(8),
	o => \avalon_slave_writedata[8]~input_o\);

-- Location: IOIBUF_X89_Y8_N55
\avalon_slave_writedata[9]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(9),
	o => \avalon_slave_writedata[9]~input_o\);

-- Location: IOIBUF_X89_Y6_N38
\avalon_slave_writedata[10]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(10),
	o => \avalon_slave_writedata[10]~input_o\);

-- Location: IOIBUF_X28_Y0_N35
\avalon_slave_writedata[11]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(11),
	o => \avalon_slave_writedata[11]~input_o\);

-- Location: IOIBUF_X62_Y0_N18
\avalon_slave_writedata[12]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(12),
	o => \avalon_slave_writedata[12]~input_o\);

-- Location: IOIBUF_X89_Y9_N4
\avalon_slave_writedata[13]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(13),
	o => \avalon_slave_writedata[13]~input_o\);

-- Location: IOIBUF_X34_Y0_N41
\avalon_slave_writedata[14]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(14),
	o => \avalon_slave_writedata[14]~input_o\);

-- Location: IOIBUF_X89_Y9_N55
\avalon_slave_writedata[15]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(15),
	o => \avalon_slave_writedata[15]~input_o\);

-- Location: IOIBUF_X54_Y0_N1
\avalon_slave_writedata[16]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(16),
	o => \avalon_slave_writedata[16]~input_o\);

-- Location: IOIBUF_X84_Y0_N52
\avalon_slave_writedata[17]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(17),
	o => \avalon_slave_writedata[17]~input_o\);

-- Location: IOIBUF_X4_Y0_N52
\avalon_slave_writedata[18]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(18),
	o => \avalon_slave_writedata[18]~input_o\);

-- Location: IOIBUF_X80_Y0_N35
\avalon_slave_writedata[19]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(19),
	o => \avalon_slave_writedata[19]~input_o\);

-- Location: IOIBUF_X32_Y0_N18
\avalon_slave_writedata[20]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(20),
	o => \avalon_slave_writedata[20]~input_o\);

-- Location: IOIBUF_X36_Y0_N52
\avalon_slave_writedata[21]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(21),
	o => \avalon_slave_writedata[21]~input_o\);

-- Location: IOIBUF_X34_Y0_N75
\avalon_slave_writedata[22]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(22),
	o => \avalon_slave_writedata[22]~input_o\);

-- Location: IOIBUF_X26_Y0_N92
\avalon_slave_writedata[23]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(23),
	o => \avalon_slave_writedata[23]~input_o\);

-- Location: IOIBUF_X84_Y0_N18
\avalon_slave_writedata[24]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(24),
	o => \avalon_slave_writedata[24]~input_o\);

-- Location: IOIBUF_X66_Y0_N75
\avalon_slave_writedata[25]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(25),
	o => \avalon_slave_writedata[25]~input_o\);

-- Location: IOIBUF_X82_Y0_N58
\avalon_slave_writedata[26]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(26),
	o => \avalon_slave_writedata[26]~input_o\);

-- Location: IOIBUF_X86_Y0_N52
\avalon_slave_writedata[27]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(27),
	o => \avalon_slave_writedata[27]~input_o\);

-- Location: IOIBUF_X2_Y0_N41
\avalon_slave_writedata[28]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(28),
	o => \avalon_slave_writedata[28]~input_o\);

-- Location: IOIBUF_X86_Y0_N35
\avalon_slave_writedata[29]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(29),
	o => \avalon_slave_writedata[29]~input_o\);

-- Location: IOIBUF_X70_Y0_N52
\avalon_slave_writedata[30]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(30),
	o => \avalon_slave_writedata[30]~input_o\);

-- Location: IOIBUF_X38_Y0_N52
\avalon_slave_writedata[31]~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_writedata(31),
	o => \avalon_slave_writedata[31]~input_o\);

-- Location: IOIBUF_X26_Y0_N58
\avalon_slave_write_n~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_avalon_slave_write_n,
	o => \avalon_slave_write_n~input_o\);

-- Location: IOIBUF_X32_Y0_N1
\reset_n~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_reset_n,
	o => \reset_n~input_o\);

-- Location: IOIBUF_X26_Y0_N75
\clock~input\ : cyclonev_io_ibuf
-- pragma translate_off
GENERIC MAP (
	bus_hold => "false",
	simulate_z_as => "z")
-- pragma translate_on
PORT MAP (
	i => ww_clock,
	o => \clock~input_o\);

-- Location: LABCELL_X18_Y16_N3
\~QUARTUS_CREATED_GND~I\ : cyclonev_lcell_comb
-- Equation(s):

-- pragma translate_off
GENERIC MAP (
	extended_lut => "off",
	lut_mask => "0000000000000000000000000000000000000000000000000000000000000000",
	shared_arith => "off")
-- pragma translate_on
;
END structure;


