# the jtag_debug service provides jtag chain debug and system clock and reset 
set jtag_debug_path [lindex [get_service_paths jtag_debug] 0]
jtag_debug_sample_clock $jtag_debug_path 
jtag_debug_sample_reset $jtag_debug_path

# the master service allows control of an avalon master port. can read and write 
set master_path [lindex [get_service_paths master] 0]
set claim_path [claim_service master $master_path ""]
# or master_read_memory $claim_path 0x0 512
set read_stuff [master_read_memory $claim_path 0x0 512] 
puts $read_stuff
close_service master $claim_path
