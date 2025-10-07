set proj_name xillydemo

set thepart xc7a35t-csg325-1

if {[string first { } $proj_dir] >= 0} {
send_msg_id xillydemo-1 error "The path to the the project directory contains white space(s): \"$proj_dir\". This is known to cause problems with Vivado. Please move the project to a path without white spaces, and try again."
}

# Create project
create_project $proj_name "$proj_dir/"

# Set project properties
set obj [get_projects $proj_name]
set_property "default_lib" "xil_defaultlib" $obj
set_property "part" $thepart $obj
set_property "simulator_language" "Mixed" $obj
set_property "source_mgmt_mode" "DisplayOnly" $obj
set_property target_language $proj_lang $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set 'sources_1' fileset properties
set obj [get_filesets sources_1]
set_property "top" "xillydemo" $obj

set files [list \
 "[file normalize "$proj_dir/../src/xillydemo.$proj_suffix"]"\
 "[file normalize "$proj_dir/../src/xillyusb.v"]"\
 "[file normalize "$proj_dir/../src/xillyusb_core.v"]"\
 "[file normalize "$proj_dir/../../core/xillyusb_core.edf"]"\
 "[file normalize "$proj_dir/../src/gtp_frontend.v"]"\
 "[file normalize "$essentials_dir/fifo_8/fifo_8.xci"]"\
 "[file normalize "$essentials_dir/fifo_32/fifo_32.xci"]"\
]

# Add files to 'sources_1' fileset
set obj [get_filesets sources_1]
add_files -norecurse -fileset $obj $files

upgrade_ip [get_ips]

# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets constrs_1] ""]} {
  create_fileset -constrset constrs_1
}

# Add files to 'constrs_1' fileset
set obj [get_filesets constrs_1]
add_files -fileset $obj -norecurse "[file normalize "$essentials_dir/xillydemo.xdc"]"

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets sim_1] ""]} {
  create_fileset -simset sim_1
}

# Create 'synth_1' run (if not found)
if {[string equal [get_runs synth_1] ""]} {
  create_run -name synth_1 -part $thepart -flow {Vivado Synthesis 2014} -strategy "Vivado Synthesis Defaults" -constrset constrs_1
}
set obj [get_runs synth_1]
set_property "part" $thepart $obj

# Create 'impl_1' run (if not found)
if {[string equal [get_runs impl_1] ""]} {
  create_run -name impl_1 -part $thepart -flow {Vivado Implementation 2014} -strategy "Vivado Implementation Defaults" -constrset constrs_1 -parent_run synth_1
}
set obj [get_runs impl_1]
set_property "part" $thepart $obj
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true $obj
set_property STEPS.POST_ROUTE_PHYS_OPT_DESIGN.IS_ENABLED true $obj
set_property STEPS.WRITE_BITSTREAM.TCL.PRE "$essentials_dir/showstopper.tcl" $obj

puts "INFO: Project created: $proj_name"

# Uncomment the two following lines for a full implementation
#launch_runs -jobs 8 impl_1 -to_step write_bitstream
#wait_on_run impl_1
