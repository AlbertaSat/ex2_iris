# util 
vcom -2008 -explicit ../../../vhdl/util/types.vhd
# vcom -2008 -explicit ../../../vhdl/util/edge_detector.vhd
vcom -2008 -explicit ../../../vhdl/util/pulse_genenerator.vhd

vcom -2008 -explicit ../../../vhdl/subsystems/swir/swir_types.vhd
vcom -2008 -explicit ../../../vhdl/subsystems/fpga/fpga_types.vhd

# vnir packages
vcom -2008 -explicit ../../../vhdl/subsystems/vnir/base/vnir_base_pkg.vhd
vcom -2008 -explicit ../../../vhdl/subsystems/vnir/base/sensor_configurer/sensor_configurer_pkg.vhd
vcom -2008 -explicit ../../../vhdl/subsystems/vnir/base/pixel_integrator/pixel_integrator_pkg.vhd
vcom -2008 -explicit ../../../vhdl/subsystems/vnir/base/lvds_decoder/lvds_decoder_pkg.vhd
vcom -2008 -explicit ../../../vhdl/subsystems/vnir/base/frame_requester/frame_requester_pkg.vhd
vcom -2008 -explicit ../../../vhdl/subsystems/vnir/vnir_pkg.vhd

# sdram packages 
vcom -2008 -explicit ../../../vhdl/subsystems/sdram/pkg/sdram_types.vhd
vcom -2008 -explicit {../../../vhdl/subsystems/sdram/pkg/imaging_buffer_pkg.vhd}
vcom -2008 -explicit {../../../vhdl/subsystems/sdram/pkg/custom_master_pkg.vhd}
vcom -2008 -explicit {../../../vhdl/subsystems/sdram/pkg/IP/VNIR_ROW_FIFO.vhd}
vcom -2008 -explicit {../../../vhdl/subsystems/sdram/pkg/IP/SWIR_Row_FIFO.vhd}

# sdram submodules
vcom -2008 -explicit {../../../vhdl/subsystems/sdram/submodules/imaging_buffer.vhd}
vcom -2008 -explicit {../../../vhdl/subsystems/sdram/submodules/header_creator.vhd}
vcom -2008 -explicit {../../../vhdl/subsystems/sdram/submodules/command_creator.vhd}

vcom -2008 -explicit {../../../vhdl/subsystems/sdram/testbenches/imaging_buffer_tb.vhd}

vsim -gui work.imaging_buffer_tb(sim)
add wave -position end sim:/imaging_buffer_tb/imaging_buffer/*
run 1 ms 
wave zoom full 