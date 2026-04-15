#!/bin/csh -f

if ( ! $?ver ) setenv ver 4_15_8ns_topo_ss

mkdir -p ./3_log

tclsh 0_script/post_dft_setup_eco.tcl | tee 3_log/${ver}_setup_eco.log
