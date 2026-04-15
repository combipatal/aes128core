if ( ! $?ver ) setenv ver 4_15_8ns_topo_ss
if ( ! $?clk_period ) setenv clk_period 8
mkdir -p 3_log
dc_shell -topo -64 -f 0_script/synthesis_script.tcl | tee 3_log/${ver}_syn_dc.log
