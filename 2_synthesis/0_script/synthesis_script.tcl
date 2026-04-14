#버전관리 
set ver $env(ver)
file mkdir ./2_output/$ver
file mkdir ./2_output/$ver/mapped
file mkdir ./2_output/$ver/unmapped

file mkdir ./4_report/$ver


# check design 
source -e -v ../.synopsys_dc.setup 
# read verilog 
analyze -format verilog {\
                        aes128_core.v\
                        aes128_core_rewrite.v\
                        cdc_toggle_sync.v\
                        clk_div2_toggle.v\
                        crc32_byte.v\
                        icg_latch.v\
                        PLL_bb_for_syn.v\
                        soc_ctrl_multiclk_soc.v\
                        sram_wrap_1rw1024x8.v\
                        top_mcu_pll_sram_multiclk_soc.v\
                        uart_rx.v\
                        uart_tx.v    
}

elaborate top_mcu_pll_sram_multiclk_soc
current_design top_mcu_pll_sram_multiclk_soc
link 
#design report

check_design > ./4_report/$ver/aes_chk_design.rpt
# ddc 
write_file -f ddc -hier -output 2_output/$ver/unmapped/top_mcu_pll_sram_multiclk_soc.ddc
#verilog file 
write -f verilog -hier -output 2_output/$ver/unmapped/top_mcu_pll_sram_multiclk_soc.v
# source constraint file 
source -e -v 1_input/constraint/constraint.con 

# Keep synthesis on a flat top-level wire-load model so the mapped netlist
# sees the same pre-layout direction as STA by default.
set auto_wire_load_selection false
set_wire_load_mode top
set_wire_load_model -name ForQA [current_design]

# latch dont use
set_dont_use [get_lib_cells */LAS*]
set_dont_use [get_lib_cells */LAR*]

# no tri
set verilogout_no_tri true

# block box 
set_dont_touch [get_cells u_mem/u_sram]
set_dont_touch [get_cells u_pll]

# grup path name 
group_path -name INS -from [all_inputs]
group_path -name OUTS -to [all_outputs]

# clean design 
set_fix_multiple_port_nets -all -buffer_constants [get_designs *]

# easy drc 
set_auto_disable_drc_nets -all 

#
# Original aggressive flow kept for reference.
#
# compile_ultra -scan
# set_critical_range 1.0 [current_design]
# compile_ultra -scan -incremental

# Preserve the top-level controller hierarchy, but allow the AES core to be
# restructured so the 2 ns clk_fast_aes domain can be optimized more freely.
set_ungroup [get_cells u_ctrl] false
# Keep the custom AES ICG instance intact so the generated clock definition on
# u_ctrl/u_icg_aes/gclk remains valid while the AES datapath is restructured.
set_ungroup [get_cells u_ctrl/u_icg_aes] false

# Keep the controller structure stable, but let DC flatten/reshape AES logic
# inside the preserved controller boundary to recover clk_fast_aes slack.
compile_ultra -scan
set_critical_range 1.0 [current_design]
compile_ultra -scan -incremental
set_critical_range 1.0 [current_design]
compile_ultra -scan -incremental


report_qor                          > ./4_report/$ver/qor.rpt
report_timing                       > ./4_report/$ver/timing.rpt
report_area -hierarchy              > ./4_report/$ver/area.rpt
report_constraint -all_violators    > ./4_report/$ver/constraint.rpt
report_clocks                        > ./4_report/$ver/clock.rpt

change_names -rules verilog -hierarchy

write_file -f ddc -h -o ./2_output/$ver/mapped/soc_gate.ddc
write -f verilog -h -o ./2_output/$ver/mapped/soc_gate.v

write_sdc ./2_output/$ver/mapped/soc_func.sdc
