set script_dir [file dirname [file normalize [info script]]]
set lab_dir [file normalize [file join $script_dir ..]]
set project_file [file join $lab_dir vivado number_demo number_demo.xpr]

if {![file exists $project_file]} {
    puts "Vivado project does not exist. Run scripts/create_vivado_project.tcl first."
    exit 1
}

open_project $project_file
reset_run synth_1
launch_runs synth_1 -jobs 2
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
puts "synth_1 status: $synth_status"

if {[string match "*Complete*" $synth_status]} {
    close_project
    exit 0
}

close_project
exit 1
