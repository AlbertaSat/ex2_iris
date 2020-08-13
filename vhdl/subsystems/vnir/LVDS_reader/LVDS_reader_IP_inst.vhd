LVDS_reader_IP_inst : LVDS_reader_IP PORT MAP (
		pll_areset	 => pll_areset_sig,
		rx_channel_data_align	 => rx_channel_data_align_sig,
		rx_in	 => rx_in_sig,
		rx_inclock	 => rx_inclock_sig,
		rx_cda_max	 => rx_cda_max_sig,
		rx_locked	 => rx_locked_sig,
		rx_out	 => rx_out_sig,
		rx_outclock	 => rx_outclock_sig
	);
