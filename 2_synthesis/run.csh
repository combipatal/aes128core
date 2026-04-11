setenv ver 4_11_4_6p5ns
source ../.synopsys_dc.setup
dc_shell -64 -f 0_script/synthesis_script.tcl | tee 3_log/${ver}_syn_dc.log
