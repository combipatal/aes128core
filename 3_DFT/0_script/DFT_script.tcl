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

# set_dft_configuration -connect_clock_gating enable
# set_dft_clock_gating_pin [get_cells u_ctrl/u_icg_aes]\
#     -pin_name test_en\
#     -control_signal ScanEnable

# #  latch 셀들을 scan chain element로 취급하지 말라는 뜻
# set_scan_element false [get_cells u_ctrl/u_icg_aes] 

#DFT 삽입 중 불필요한 추가 최적화를 막고, 
#설계 이름도 유지해서 원래 설계와 비교하기 쉽게 만드는 설정
set_dft_insertion_configuration -synthesis_optimization none\
    -preserve_design_name true

# Synopsys가 삽입하는 DFT 전용 로직을 어느 계층/이름 아래 둘지 지정
#set_dft_location top_mcu_pll_sram_multiclk_soc/U_SNPS_DFT_LOGIC

set_dft_signal -view exist -type ScanClock  -port ref_clk   -timing {45 55}
set_dft_signal -view exist -type ScanEnable -port scan_en   -active_state 1 
set_dft_signal -view exist -type Reset      -port rst_n     -active_state 0

set_dft_signal -view exist -type TestMode -active_state 1 -port test_mode 
# scan_in, scan_out
set_dft_signal -view spec  -type ScanDataIn     -port scan_in
set_dft_signal -view spec  -type ScanDataOut    -port scan_out

set_scan_path chain0 -view spec -scan_data_in scan_in -scan_data_out scan_out

#set_dft_configuration -scan_compression enable

#scan chain 개수 1개
set_scan_configuration -test_mode all -chain_count 1
#scan FF 스타일을 muxed scan flop으로 
set_scan_configuration -test_mode all -style multiplexed_flip_flop
#internal clock를 별도로 scan clock로 쓰지 않음
set_scan_configuration -test_mode all -internal_clocks none

set_dft_configuration -fix_bus enable

#clock, reset 수정 X
set auto_fix 0

#DFT 삽입 전에 test protocol을 생성하고, DFT rule check와 scan 구조확인
create_test_protocol
dft_drc                             > ./4_report/${ver}/pre_dft.rpt
dft_drc -verbose                    > ./4_report/${ver}/pre_drc_verbose.rpt
preview_dft -show scan_summary      > ./4_report/${ver}/preview_dft.rpt

#DFT/합성 과정에서 새로 삽입되는 인스턴스 이름 앞에 DFTC_를 붙임
set compile_instance_name_prefix DFTC_

insert_dft

set_case_analysis 0 [get_ports scan_en]
set_case_analysis 0 [get_ports test_mode]
set_critical_range 0.5 [current_design]
compile_ultra -scan -incremental
report_qor > ./4_report/${ver}/dft_qor_func.rpt

current_test_mode Internal_scan
dft_drc -verbose    > ./4_report/${ver}/insert_drc_internal.dft

# Change names
change_names -rules verilog -hierarchy

write_test_protocol -test_mode Internal_scan\
    -out ./2_output/${ver}/scan_internal.spf\
    -names verilog

write_scan_def -out ./2_output/${ver}/scan.def

write -f verilog  -hierarchy -output ./2_output/${ver}/aes_128_internal.v
write_file -f ddc -hierarchy -output ./2_output/${ver}/aes_128_internal.ddc

current_test_mode Internal_scan

report_scan_configuration                       >  ./4_report/${ver}/scan_config_internal.rpt
report_dft_signal -view exist                   >  ./4_report/${ver}/dft_signals_internal.rpt
report_dft_signal -view spec                    >> ./4_report/${ver}/dft_signals_internal.rpt
report_scan_path -view existing_dft -chain all  >  ./4_report/${ver}/scan_chains_internal.rpt
report_qor                                      >  ./4_report/${ver}/dft_qor_internal.rpt
report_area -hierarchy                          >  ./4_report/${ver}/dft_internal_area.rpt
