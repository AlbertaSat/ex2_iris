# This file is used to create a new quartus project with desired settings

# --------------------------------------------------------------------------------------

# INSTRUCTIONS

# STEP 1/3:
# set project name here:
set project_name imaging_buffer

# STEP 2/3:
# set path to pins file 
set pins_file {C:\Users\tharu\Desktop\absat_projects\ex2_iris\project_files\global_scripts\pins_de10nano.tcl}

# STEP 3/3: 
# run this file in the directory where you want the new project (using powershell if Windows)
# command:
# quartus_sh -t .\..\scripts\syn\quartus_new_project.tcl

# OPTIONAL:
# set quartus project revision name
set revision_name $project_name
# --------------------------------------------------------------------------------------

# Load Quartus Prime Tcl Project package
package require ::quartus::project
load_package flow 

project_new $project_name -revision $revision_name -overwrite

# assignments
set_global_assignment -name FAMILY "Cyclone V"
set_global_assignment -name DEVICE 5CSEBA6U23I7
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY output_files

set_global_assignment -name DEVICE_FILTER_PACKAGE FBGA
set_global_assignment -name CYCLONEII_RESERVE_NCEO_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
set_global_assignment -name POWER_PRESET_COOLING_SOLUTION "23 MM HEAT SINK WITH 200 LFPM AIRFLOW"
set_global_assignment -name POWER_BOARD_THERMAL_MODEL "NONE (CONSERVATIVE)"
set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id Top
set_global_assignment -name PARTITION_FITTER_PRESERVATION_LEVEL PLACEMENT_AND_ROUTING -section_id Top
set_global_assignment -name PARTITION_COLOR 16764057 -section_id Top
set_global_assignment -name TIMING_ANALYZER_MULTICORNER_ANALYSIS ON

set_global_assignment -name VHDL_INPUT_VERSION VHDL_2008

# top level file
# set_global_assignment -name VHDL_FILE ../scripts/src/sdram_hw_test.vhd

# ip files to include
# set_global_assignment -name VERILOG_FILE ../../ip/debounce/debounce.v

# packages 
set_global_assignment -name VHDL_FILE ../../../vhdl/util/types.vhd
set_global_assignment -name VHDL_FILE ../../../vhdl/util/edge_detector.vhd
set_global_assignment -name VHDL_FILE ../../../vhdl/util/pulse_genenerator.vhd
set_global_assignment -name VHDL_FILE ../../../vhdl/subsystems/swir/swir_types.vhd
set_global_assignment -name VHDL_FILE ../../../vhdl/subsystems/fpga/fpga_types.vhd
set_global_assignment -name VHDL_FILE ../../../vhdl/subsystems/vnir/base/vnir_base_pkg.vhd
set_global_assignment -name VHDL_FILE ../../../vhdl/subsystems/vnir/base/sensor_configurer/sensor_configurer_pkg.vhd
set_global_assignment -name VHDL_FILE ../../../vhdl/subsystems/vnir/base/pixel_integrator/pixel_integrator_pkg.vhd
set_global_assignment -name VHDL_FILE ../../../vhdl/subsystems/vnir/base/lvds_decoder/lvds_decoder_pkg.vhd
set_global_assignment -name VHDL_FILE ../../../vhdl/subsystems/vnir/base/frame_requester/frame_requester_pkg.vhd
set_global_assignment -name VHDL_FILE ../../../vhdl/subsystems/vnir/vnir_pkg.vhd
set_global_assignment -name VHDL_FILE ../../../vhdl/subsystems/sdram/pkg/sdram_types.vhd
set_global_assignment -name VHDL_FILE {../../../vhdl/subsystems/sdram/pkg/imaging_buffer_pkg.vhd}
set_global_assignment -name VHDL_FILE {../../../vhdl/subsystems/sdram/pkg/custom_master_pkg.vhd}
set_global_assignment -name VHDL_FILE {../../../vhdl/subsystems/sdram/pkg/IP/VNIR_ROW_FIFO.vhd}
set_global_assignment -name VHDL_FILE {../../../vhdl/subsystems/sdram/pkg/IP/SWIR_Row_FIFO.vhd}

# sdram submodules
set_global_assignment -name VHDL_FILE {../../../vhdl/subsystems/sdram/submodules/imaging_buffer.vhd}
set_global_assignment -name VHDL_FILE {../../../vhdl/subsystems/sdram/submodules/header_creator.vhd}
set_global_assignment -name VHDL_FILE {../../../vhdl/subsystems/sdram/submodules/command_creator.vhd}

# get pin assignments  
source $pins_file

# Including default assignments
set_global_assignment -name REVISION_TYPE BASE -family "Cyclone V"
set_global_assignment -name TIMING_ANALYZER_REPORT_WORST_CASE_TIMING_PATHS OFF -family "Cyclone V"
set_global_assignment -name TIMING_ANALYZER_CCPP_TRADEOFF_TOLERANCE 0 -family "Cyclone V"
set_global_assignment -name TDC_CCPP_TRADEOFF_TOLERANCE 30 -family "Cyclone V"
set_global_assignment -name TIMING_ANALYZER_DO_CCPP_REMOVAL ON -family "Cyclone V"
set_global_assignment -name DISABLE_LEGACY_TIMING_ANALYZER OFF -family "Cyclone V"
set_global_assignment -name SYNTH_TIMING_DRIVEN_SYNTHESIS ON -family "Cyclone V"
set_global_assignment -name SYNCHRONIZATION_REGISTER_CHAIN_LENGTH 3 -family "Cyclone V"
set_global_assignment -name SYNTH_RESOURCE_AWARE_INFERENCE_FOR_BLOCK_RAM ON -family "Cyclone V"
set_global_assignment -name STRATIXV_CONFIGURATION_SCHEME "PASSIVE SERIAL" -family "Cyclone V"
set_global_assignment -name OPTIMIZE_HOLD_TIMING "ALL PATHS" -family "Cyclone V"
set_global_assignment -name OPTIMIZE_MULTI_CORNER_TIMING ON -family "Cyclone V"
set_global_assignment -name AUTO_DELAY_CHAINS ON -family "Cyclone V"
set_global_assignment -name CRC_ERROR_OPEN_DRAIN ON -family "Cyclone V"
set_global_assignment -name ACTIVE_SERIAL_CLOCK FREQ_100MHZ -family "Cyclone V"
set_global_assignment -name ADVANCED_PHYSICAL_OPTIMIZATION ON -family "Cyclone V"
set_global_assignment -name ENABLE_OCT_DONE OFF -family "Cyclone V"

# Commit assignments
export_assignments