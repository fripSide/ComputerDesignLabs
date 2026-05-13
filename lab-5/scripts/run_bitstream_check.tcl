set script_dir [file dirname [file normalize [info script]]]
set lab_dir [file normalize [file join $script_dir ..]]
set out_dir [file join $lab_dir vivado bitstream_check]

file mkdir $out_dir

read_verilog [file join $lab_dir src hex_to_7seg.v]
read_verilog [file join $lab_dir src scan_7seg.v]
read_verilog [file join $lab_dir src board_number_demo.v]
read_xdc [file join $lab_dir constraints Nexys4DDR_NumberDemo.xdc]

synth_design -top board_number_demo -part xc7a100tcsg324-1
opt_design
place_design
route_design
write_bitstream -force [file join $out_dir board_number_demo.bit]

puts "Generated bitstream: [file join $out_dir board_number_demo.bit]"
exit 0
