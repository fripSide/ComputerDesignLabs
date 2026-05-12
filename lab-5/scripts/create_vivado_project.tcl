set script_dir [file dirname [file normalize [info script]]]
set lab_dir [file normalize [file join $script_dir ..]]
set project_dir [file join $lab_dir vivado number_demo]

file mkdir $project_dir

create_project number_demo $project_dir -part xc7a100tcsg324-1 -force
set_property board_part digilentinc.com:nexys4_ddr:part0:1.1 [current_project]

add_files [file join $lab_dir src hex_to_7seg.v]
add_files [file join $lab_dir src scan_7seg.v]
add_files [file join $lab_dir src board_number_demo.v]
add_files -fileset constrs_1 [file join $lab_dir constraints Nexys4DDR_NumberDemo.xdc]

set_property top board_number_demo [current_fileset]
update_compile_order -fileset sources_1

puts "Created Vivado project: $project_dir"
