--Copyright (C) 2017  Intel Corporation. All rights reserved.
--Your use of Intel Corporation's design tools, logic functions 
--and other software and tools, and its AMPP partner logic 
--functions, and any output files from any of the foregoing 
--(including device programming or simulation files), and any 
--associated documentation or information are expressly subject 
--to the terms and conditions of the Intel Program License 
--Subscription Agreement, the Intel Quartus Prime License Agreement,
--the Intel MegaCore Function License Agreement, or other 
--applicable license agreement, including, without limitation, 
--that your use is for the sole purpose of programming logic 
--devices manufactured by Intel and sold by Intel or its 
--authorized distributors.  Please refer to the applicable 
--agreement for further details.


FUNCTION LVDS_reader_IP 
(
	pll_areset,
	rx_channel_data_align[0..0],
	rx_in[0..0],
	rx_inclock
)

RETURNS (
	rx_cda_max[0..0],
	rx_locked,
	rx_out[9..0],
	rx_outclock
);
