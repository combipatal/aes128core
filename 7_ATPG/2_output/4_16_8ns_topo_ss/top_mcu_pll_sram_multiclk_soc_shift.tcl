
# PrimeTime (R) Tcl script created by tmax2pt.tcl
# Creation time: Thu Apr 16 10:47:03 2026
# tmax2pt.tcl version: P-2019.03: 2019/01/23 02:04:06 
# arguments: /DATA/home/edu135/aes128_core/7_ATPG/2_output/4_16_8ns_topo_ss/top_mcu_pll_sram_multiclk_soc_shift.tcl -mode shift -wft _default_WFT_ -replace


# Note: any existing constraints or exceptions may invalidate those
# here.  Uncomment the following to reset everything except the linked
# design.
# reset_design

set timing_enable_preset_clear_arcs true

    

# clocks
suppress_message UITE-210
create_clock -name ref_clk_wft1 -period 100 -waveform { 45 55 } [get_ports ref_clk]
# Clock rst_n is constrained off, so no create_clock command is printed for it.
unsuppress_message UITE-210

# Note: uncomment any of the following sections as appropriate.
#
## pre-layout design
#set clock_delay 0
#set_clock_latency $clock_delay [all_clocks]
#
## post-layout design
#set_propagated_clock [all_clocks]
#
#set intra_clock_skew 0
#set inter_clock_skew 0
#set_clock_uncertainty $intra_clock_skew [all_clocks]
#foreach_in_collection from_clock [all_clocks] {
#  foreach_in_collection to_clock [all_clocks] {
#    if {[get_attribute $from_clock full_name] !=
#        [get_attribute $to_clock full_name]} {
#      set_clock_uncertainty $inter_clock_skew -from $from_clock -to $to_clock
#    }
#  }
#}
    

# virtual clocks for PI, PO & PIO events
suppress_message UITE-121
create_clock -name forcePI_wft1 -period 100  -waveform { 0 1 } 
create_clock -name measurePO_wft1 -period 100  -waveform { 0 40 } 
unsuppress_message UITE-121

# PI & PIO settings
set_case_analysis 1 [get_ports rst_n]
set_input_delay 0 -clock forcePI_wft1  [get_ports start]
set_input_delay 0 -clock forcePI_wft1  [get_ports uart_rxd]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[127]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[126]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[125]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[124]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[123]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[122]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[121]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[120]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[119]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[118]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[117]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[116]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[115]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[114]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[113]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[112]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[111]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[110]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[109]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[108]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[107]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[106]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[105]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[104]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[103]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[102]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[101]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[100]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[99]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[98]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[97]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[96]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[95]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[94]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[93]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[92]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[91]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[90]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[89]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[88]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[87]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[86]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[85]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[84]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[83]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[82]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[81]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[80]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[79]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[78]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[77]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[76]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[75]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[74]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[73]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[72]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[71]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[70]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[69]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[68]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[67]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[66]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[65]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[64]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[63]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[62]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[61]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[60]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[59]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[58]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[57]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[56]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[55]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[54]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[53]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[52]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[51]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[50]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[49]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[48]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[47]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[46]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[45]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[44]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[43]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[42]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[41]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[40]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[39]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[38]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[37]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[36]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[35]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[34]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[33]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[32]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[31]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[30]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[29]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[28]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[27]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[26]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[25]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[24]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[23]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[22]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[21]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[20]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[19]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[18]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[17]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[16]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[15]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[14]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[13]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[12]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[11]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[10]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[9]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[8]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[7]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[6]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[5]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[4]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[3]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[2]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[1]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_key_ext[0]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[127]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[126]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[125]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[124]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[123]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[122]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[121]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[120]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[119]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[118]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[117]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[116]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[115]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[114]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[113]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[112]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[111]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[110]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[109]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[108]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[107]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[106]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[105]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[104]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[103]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[102]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[101]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[100]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[99]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[98]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[97]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[96]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[95]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[94]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[93]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[92]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[91]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[90]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[89]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[88]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[87]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[86]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[85]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[84]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[83]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[82]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[81]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[80]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[79]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[78]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[77]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[76]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[75]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[74]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[73]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[72]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[71]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[70]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[69]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[68]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[67]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[66]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[65]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[64]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[63]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[62]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[61]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[60]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[59]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[58]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[57]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[56]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[55]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[54]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[53]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[52]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[51]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[50]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[49]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[48]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[47]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[46]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[45]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[44]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[43]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[42]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[41]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[40]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[39]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[38]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[37]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[36]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[35]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[34]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[33]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[32]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[31]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[30]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[29]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[28]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[27]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[26]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[25]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[24]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[23]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[22]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[21]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[20]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[19]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[18]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[17]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[16]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[15]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[14]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[13]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[12]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[11]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[10]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[9]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[8]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[7]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[6]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[5]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[4]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[3]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[2]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[1]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_pt_ext[0]]
set_input_delay 0 -clock forcePI_wft1  [get_ports aes_vec_valid]
set_case_analysis 1 [get_ports test_mode]
set_case_analysis 1 [get_ports scan_en]
set_input_delay 0 -clock forcePI_wft1  [get_ports scan_in]
set_input_delay 0 -clock forcePI_wft1  [get_ports test_si2]
set_input_delay 0 -clock forcePI_wft1  [get_ports test_si3]
set_input_delay 0 -clock forcePI_wft1  [get_ports test_si4]

# PO and PIO settings
set_output_delay 0 -clock measurePO_wft1  [get_ports uart_txd] -clock_fall
set_output_delay 0 -clock measurePO_wft1  [get_ports done] -clock_fall
set_output_delay 0 -clock measurePO_wft1  [get_ports pass] -clock_fall
set_output_delay 0 -clock measurePO_wft1  [get_ports clk_fast] -clock_fall
set_output_delay 0 -clock measurePO_wft1  [get_ports clk_div2] -clock_fall
set_output_delay 0 -clock measurePO_wft1  [get_ports clk_div4] -clock_fall
set_output_delay 0 -clock measurePO_wft1  [get_ports clk_div8] -clock_fall
set_output_delay 0 -clock measurePO_wft1  [get_ports scan_out] -clock_fall
set_output_delay 0 -clock measurePO_wft1  [get_ports test_so2] -clock_fall
set_output_delay 0 -clock measurePO_wft1  [get_ports test_so3] -clock_fall
set_output_delay 0 -clock measurePO_wft1  [get_ports test_so4] -clock_fall

# -nopi_changes

# black_boxes, and empty_boxes
suppress_message UITE-216
set_false_path -through [get_cells u_mem/u_sram]
set_false_path -to [get_cells u_mem/u_sram]
set_false_path -from [get_cells u_mem/u_sram]
unsuppress_message UITE-216

# nonscan sequential elements 
set_false_path -to [get_cells u_ctrl/u_icg_aes/en_lat_reg]
set_case_analysis 1 u_ctrl/u_icg_aes/en_lat_reg/Q

# masked scan cells
