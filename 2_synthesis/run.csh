setenv ver 4_11_3_6ns
source ../.synopsys_dc.setup
dc_shell -64 -f 0_script/synthesis_script.tcl | tee 3_log/${ver}_syn_dc.log
