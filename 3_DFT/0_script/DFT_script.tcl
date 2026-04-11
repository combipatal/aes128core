set ver $env(ver)

source -e -v ./.synopsys_dc.setups

read_verilog ../2_Synthesis/2_Output/$ver/mapped/ORCA_gate.v
current_design top_mcu_pll_sram_multiclk_soc
link 

set test_default_period 100
set test_default_bidir_delay 0
set test_default_delay 0
set test_default_strobe 40

set test_enable_dft_drc
set test_stil_netlist_format verilog 

set_auto_disable_drc_nets -scan true
set_fix_multiple_port_nets -all -buffer_constants [find design "*"]
set verilogout_no_tri true

set test_dft_drc_ungate_clocks "true"
set power_cg_auto_identify true

set_dft_configuration -connect_clock_gating enable
set_dft_clock_gating_pin [get_cells u_ctrl/u_icg_aes]\
    -pin_name test_en\
    -control_signal scan-enable

#  latch 셀들을 scan chain element로 취급하지 말라는 뜻
set_scan_element false [get_cells u_ctrl/u_icg_aes] 

#DFT 삽입 중 불필요한 추가 최적화를 막고, 
#설계 이름도 유지해서 원래 설계와 비교하기 쉽게 만드는 설정
set_dft_insertion_configuration -synthesis_optimization none\
    -preserve_design_name true

# Synopsys가 삽입하는 DFT 전용 로직을 어느 계층/이름 아래 둘지 지정
set_dft_location top_mcu_pll_sram_multiclk_soc/U_SNPS_DFT_LOGIC

