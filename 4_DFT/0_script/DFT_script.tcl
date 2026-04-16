set ver $env(ver)
file mkdir ./2_output
file mkdir ./2_output/${ver}
file mkdir ./4_report
file mkdir ./4_report/${ver}
file mkdir ./3_log


source -e -v ../.synopsys_dc.setup

read_file -format ddc ../2_synthesis/2_output/${ver}/mapped/soc_gate.ddc
current_design top_mcu_pll_sram_multiclk_soc
link 

set test_default_period 100
set test_default_bidir_delay 0
set test_default_delay 0
set test_default_strobe 40

set test_enable_dft_drc true
set test_stil_netlist_format verilog 

set_auto_disable_drc_nets -scan true
set_fix_multiple_port_nets -all -buffer_constants [find design "*"]
set verilogout_no_tri true

set test_dft_drc_ungate_clocks "true"
set power_cg_auto_identify true

set_dft_configuration -connect_clock_gating enable
set_dft_clock_gating_pin [get_cells u_ctrl/u_icg_aes]\
    -pin_name test_en\
    -control_signal ScanEnable

# latch 기반 ICG 셀은 scan element로 취급하지 않는다
set_scan_element false [get_cells u_ctrl/u_icg_aes]

# 이름은 유지하되 scan 삽입 후 일반 최적화는 허용한다
set_dft_insertion_configuration \
    -preserve_design_name true

# 필요하면 DFT 전용 로직의 삽입 위치를 고정할 수 있다
#set_dft_location top_mcu_pll_sram_multiclk_soc/U_SNPS_DFT_LOGIC

set_dft_signal -view exist -type ScanClock  -port ref_clk   -timing {45 55}
set_dft_signal -view exist -type ScanEnable -port scan_en   -active_state 1 
set_dft_signal -view exist -type Reset      -port rst_n     -active_state 0

set_dft_signal -view exist -type TestMode -active_state 1 -port test_mode 
# scan 입출력 포트를 지정한다
set_dft_signal -view spec  -type ScanDataIn     -port scan_in
set_dft_signal -view spec  -type ScanDataOut    -port scan_out

set_scan_path chain0 -view spec -scan_data_in scan_in -scan_data_out scan_out

#set_dft_configuration -scan_compression enable

# scan chain 개수를 4개로 둔다
set_scan_configuration -test_mode all -chain_count 4
# scan FF 스타일은 muxed scan flop으로 둔다
set_scan_configuration -test_mode all -style multiplexed_flip_flop
# internal clock는 별도 scan clock로 쓰지 않는다
set_scan_configuration -test_mode all -internal_clocks none

set_dft_configuration -fix_bus enable

# clock, reset 자동 수정은 하지 않는다
set auto_fix 0

# DFT 삽입 전에 test protocol과 DFT rule check를 수행한다
create_test_protocol
dft_drc                             > ./4_report/${ver}/pre_dft.rpt
dft_drc -verbose                    > ./4_report/${ver}/pre_drc_verbose.rpt
preview_dft -show scan_summary      > ./4_report/${ver}/preview_dft.rpt

# DFT에서 새로 넣는 인스턴스 이름 앞에 DFTC_를 붙인다
set compile_instance_name_prefix DFTC_

insert_dft

set_case_analysis 0 [get_ports scan_en]
set_case_analysis 0 [get_ports test_mode]

# scan 후 fanout이 커지는 CDC source flop은 복제를 허용한다
set_register_replication -max_fanout 16 [get_cells u_ctrl/u_ct_cdc/pulse_dst_reg]

# CDC 출력의 transition을 강하게 제한한다
current_design cdc_toggle_sync_1
set_max_transition 0.20 [get_ports pulse_dst]
current_design top_mcu_pll_sram_multiclk_soc

set_critical_range 0.5 [current_design]
compile_ultra -scan -incremental
report_qor > ./4_report/${ver}/dft_qor_func.rpt

current_test_mode Internal_scan
dft_drc -verbose    > ./4_report/${ver}/insert_drc_internal.dft

# 최종 netlist 이름을 verilog 규칙에 맞게 정리한다
change_names -rules verilog -hierarchy

write_test_protocol -test_mode Internal_scan\
    -out ./2_output/${ver}/scan_internal.spf\
    -names verilog

write_scan_def -out ./2_output/${ver}/scan.def

write -f verilog  -hierarchy -output ./2_output/${ver}/aes_128_internal.v
write_file -f ddc -hierarchy -output ./2_output/${ver}/aes_128_internal.ddc
write_sdf -version 2.1 ./2_output/${ver}/aes_128_internal.sdf

current_test_mode Internal_scan

report_scan_configuration                       >  ./4_report/${ver}/scan_config_internal.rpt
report_dft_signal -view exist                   >  ./4_report/${ver}/dft_signals_internal.rpt
report_dft_signal -view spec                    >> ./4_report/${ver}/dft_signals_internal.rpt
report_scan_path -view existing_dft -chain all  >  ./4_report/${ver}/scan_chains_internal.rpt
report_qor                                      >  ./4_report/${ver}/dft_qor_internal.rpt
report_area -hierarchy                          >  ./4_report/${ver}/dft_internal_area.rpt
