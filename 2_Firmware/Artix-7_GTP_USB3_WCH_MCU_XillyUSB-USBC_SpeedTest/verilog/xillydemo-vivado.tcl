set proj_dir [file normalize [file dirname [info script]]/vivado]
set essentials_dir [file normalize "$proj_dir/../../vivado-essentials"]
set proj_lang Verilog
set proj_suffix v

source $essentials_dir/main.tcl
