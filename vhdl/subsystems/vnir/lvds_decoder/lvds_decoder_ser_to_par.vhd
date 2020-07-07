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

LIBRARY altera_mf;
USE altera_mf.all;

entity lvds_decoder_ser_to_par is
generic (
    n_channels : integer;
    bit_width  : integer
);
port (
    rx_channel_data_align   : in std_logic_vector (n_channels-1 downto 0);
    rx_in                   : in std_logic_vector (n_channels-1 downto 0);
    rx_inclock              : in std_logic;
    rx_out                  : out std_logic_vector (bit_width*n_channels-1 downto 0);
    rx_outclock             : out std_logic
);
end entity lvds_decoder_ser_to_par;

architecture rtl of lvds_decoder_ser_to_par is
    component altlvds_rx
    generic (
        buffer_implementation                   : string;
        cds_mode                                : string;
        common_rx_tx_pll                        : string;
        data_align_rollover                     : natural;
        data_rate                               : string;
        deserialization_factor                  : natural;
        dpa_initial_phase_value                 : natural;
        dpll_lock_count                         : natural;
        dpll_lock_window                        : natural;
        enable_clock_pin_mode                   : string;
        enable_dpa_align_to_rising_edge_only    : string;
        enable_dpa_calibration                  : string;
        enable_dpa_fifo                         : string;
        enable_dpa_initial_phase_selection      : string;
        enable_dpa_mode                         : string;
        enable_dpa_pll_calibration              : string;
        enable_soft_cdr_mode                    : string;
        implement_in_les                        : string;
        inclock_boost                           : natural;
        inclock_data_alignment                  : string;
        inclock_period                          : natural;
        inclock_phase_shift                     : natural;
        input_data_rate                         : natural;
        intended_device_family                  : string;
        lose_lock_on_one_change                 : string;
        lpm_hint                                : string;
        lpm_type                                : string;
        number_of_channels                      : natural;
        outclock_resource                       : string;
        pll_operation_mode                      : string;
        pll_self_reset_on_loss_lock             : string;
        port_rx_channel_data_align              : string;
        port_rx_data_align                      : string;
        refclk_frequency                        : string;
        registered_data_align_input             : string;
        registered_output                       : string;
        reset_fifo_at_first_lock                : string;
        rx_align_data_reg                       : string;
        sim_dpa_is_negative_ppm_drift           : string;
        sim_dpa_net_ppm_variation               : natural;
        sim_dpa_output_clock_phase_shift        : natural;
        use_coreclock_input                     : string;
        use_dpll_rawperror                      : string;
        use_external_pll                        : string;
        use_no_phase_shift                      : string;
        x_on_bitslip                            : string;
        clk_src_is_pll                          : string
    );
    port (
        rx_channel_data_align   : in std_logic_vector (n_channels-1 downto 0);
        rx_in                   : in std_logic_vector (n_channels-1 downto 0);
        rx_inclock              : in std_logic;
        rx_out                  : out std_logic_vector (bit_width*n_channels-1 downto 0);
        rx_outclock             : out std_logic 
    );
    end component;
begin
    ALTLVDS_RX_component : ALTLVDS_RX generic map (
		buffer_implementation => "RAM",
		cds_mode => "UNUSED",
		common_rx_tx_pll => "OFF",
		data_align_rollover => bit_width,
		data_rate => "480.0 Mbps",
		deserialization_factor => bit_width,
		dpa_initial_phase_value => 0,
		dpll_lock_count => 0,
		dpll_lock_window => 0,
		enable_clock_pin_mode => "UNUSED",
		enable_dpa_align_to_rising_edge_only => "OFF",
		enable_dpa_calibration => "ON",
		enable_dpa_fifo => "UNUSED",
		enable_dpa_initial_phase_selection => "OFF",
		enable_dpa_mode => "OFF",
		enable_dpa_pll_calibration => "OFF",
		enable_soft_cdr_mode => "OFF",
		implement_in_les => "OFF",
		inclock_boost => 0,
		inclock_data_alignment => "EDGE_ALIGNED",
		inclock_period => 4167,
		inclock_phase_shift => 1042,
		input_data_rate => 480,
		intended_device_family => "Cyclone V",
		lose_lock_on_one_change => "UNUSED",
		lpm_hint => "CBX_MODULE_PREFIX=lvds_rx_10_17",
		lpm_type => "altlvds_rx",
		number_of_channels => n_channels,
		outclock_resource => "Dual-Regional clock",
		pll_operation_mode => "NORMAL",
		pll_self_reset_on_loss_lock => "UNUSED",
		port_rx_channel_data_align => "PORT_USED",
		port_rx_data_align => "PORT_UNUSED",
		refclk_frequency => "240.000000 MHz",
		registered_data_align_input => "UNUSED",
		registered_output => "ON",
		reset_fifo_at_first_lock => "UNUSED",
		rx_align_data_reg => "RISING_EDGE",
		sim_dpa_is_negative_ppm_drift => "OFF",
		sim_dpa_net_ppm_variation => 0,
		sim_dpa_output_clock_phase_shift => 0,
		use_coreclock_input => "OFF",
		use_dpll_rawperror => "OFF",
		use_external_pll => "OFF",
		use_no_phase_shift => "ON",
		x_on_bitslip => "ON",
		clk_src_is_pll => "off"
	) port map (
		rx_channel_data_align => rx_channel_data_align,
		rx_in => rx_in,
		rx_inclock => rx_inclock,
		rx_out => rx_out,
		rx_outclock => rx_outclock
	);
end architecture rtl;
