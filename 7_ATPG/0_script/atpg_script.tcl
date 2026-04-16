# 실행 시각을 로그 맨 앞에 남긴다.
sh date

# 현재 ATPG는 DFT 완료 버전 이름 하나만 받는다.
set ver [getenv ver]

# ATPG 작업 디렉터리와 프로젝트 루트를 계산한다.
set ATPG_DIR [pwd]
set PROJECT_ROOT [file normalize [file join $ATPG_DIR ..]]

# 현재 설계 top 이름은 고정으로 둔다.
set DESIGN_NAME top_mcu_pll_sram_multiclk_soc

# 현재 ATPG 입력은 post-DFT netlist와 내부 scan SPF다.
set NETLIST [file normalize [file join $PROJECT_ROOT 4_DFT 2_output $ver aes_128_internal.v]]
set SPF_FILE [file normalize [file join $PROJECT_ROOT 4_DFT 2_output $ver scan_internal.spf]]

# 라이브러리 모델은 현재 프로젝트의 SAED32 EDK 기준으로 읽는다.
set LIB_RVT [file normalize [file join $PROJECT_ROOT SAED32_EDK lib stdcell_rvt verilog saed32nm.tv]]
set LIB_HVT [file normalize [file join $PROJECT_ROOT SAED32_EDK lib stdcell_hvt verilog saed32nm_hvt.tv]]
set LIB_LVT [file normalize [file join $PROJECT_ROOT SAED32_EDK lib stdcell_lvt verilog saed32nm_lvt.tv]]
set LIB_IO [file normalize [file join $PROJECT_ROOT .. DC_LAB_3 4_ATPG tmax_model saed32nm_std_io_fc.tv]]
set LIB_COMMON [file normalize [file join $PROJECT_ROOT .. DC_LAB_3 4_ATPG tmax_model common.v]]
set LIB_PLL [file normalize [file join $PROJECT_ROOT SAED32_EDK lib pll verilog PLL.v]]
set LIB_SRAM [file normalize [file join $PROJECT_ROOT SAED32_EDK lib sram verilog saed32sram.tv]]

# 산출물 경로를 한 번만 만든다.
set OUTPUT_DIR [file normalize [file join $ATPG_DIR 2_output $ver]]
set REPORT_DIR [file normalize [file join $ATPG_DIR 4_report $ver]]
set LOG_FILE [file normalize [file join $ATPG_DIR 3_log $ver tmax.log]]

# 상세 메시지는 별도 로그 파일에 저장한다.
set_messages -replace -log $LOG_FILE -level expert

# 현재 ATPG 입력 정보를 먼저 출력한다.
puts "ATPG version : $ver"
puts "Top design   : $DESIGN_NAME"
puts "Netlist      : $NETLIST"
puts "SPF          : $SPF_FILE"

# 필수 입력 파일이 없으면 바로 멈춘다.
if {![file exists $NETLIST]} {
    puts "ERROR: DFT netlist not found -> $NETLIST"
    exit 1
}
if {![file exists $SPF_FILE]} {
    puts "ERROR: scan SPF not found -> $SPF_FILE"
    exit 1
}

# ATPG 라이브러리를 먼저 읽어서 셀 이름을 해석한다.
read_netlist -library $LIB_RVT
read_netlist -library $LIB_HVT
read_netlist -library $LIB_LVT
read_netlist -library $LIB_IO
read_netlist -library $LIB_COMMON
read_netlist -library $LIB_PLL -define TETRAMAX
read_netlist -library $LIB_SRAM

# SRAM 매크로는 scan 로직이 아니므로 black box로 둔다.
set_build -black_box [list SRAM1RW1024x8]

# post-DFT gate netlist를 ATPG 대상으로 읽는다.
read_netlist $NETLIST

# 부동 입력 경고는 test-only 포트 때문에 완화한다.
set_rules B12 ignore

# 동등 구조 학습을 켜서 ATPG 모델을 안정화한다.
set_learning -atpg_equivalence

# 현재 top 기준 ATPG 내부 모델을 만든다.
run_build_model $DESIGN_NAME

# reset과 내부 clock는 실제 scan 구조에 맞춰 DRC를 완화한다.
set_drc -allow_unstable_set_resets
set_drc -clock -dynamic -nodisturb_clock_grouping

# DFT에서 나온 internal SPF로 scan DRC를 수행한다.
run_drc $SPF_FILE

# shift와 capture 제약도 같이 뽑아두면 이후 확인이 쉽다.
source /tools/synopsys/syn/W-2024.09-SP5-5/auxx/syn/tmax/tmax2pt.tcl
write_timing_constraints [file join $OUTPUT_DIR ${DESIGN_NAME}_shift.tcl] -mode shift -wft _default_WFT_ -replace
write_timing_constraints [file join $OUTPUT_DIR ${DESIGN_NAME}_capture.tcl] -mode capture -wft _default_WFT_ -replace

# stuck-at fault를 기준으로 전체 fault set을 만든다.
set_faults -fault_coverage
set_faults -model stuck
set_faults -report collapsed
add_faults -all

# 외부 버스 Z는 X로 처리해서 ATPG 해석을 단순하게 만든다.
set_buses -external_z X

# 4개 프로세스로 ATPG 시뮬레이션과 pattern search를 수행한다.
set_simulation -xclock_gives_xout -num_processes 4
set_atpg -num_processes 4

# 기본 fill, merge, power 옵션은 읽기 쉬운 보수적 값만 남긴다.
set_atpg -fill adjacent -coverage 98
set_atpg -merge high -decision random -store
set_atpg -power_budget min
set_atpg -power_effort high

# 내부 scan 구조 기준으로 기본 ATPG를 실행한다.
run_atpg -auto

# 결과를 먼저 로그에 한 번 요약한다.
report_settings
report_summaries patterns faults memory_usage cpu_usage

# 가장 먼저 보는 STIL과 WGL 패턴을 저장한다.
write_patterns [file join $OUTPUT_DIR ${DESIGN_NAME}_full_serial.stil] -format stil -replace -serial
write_patterns [file join $OUTPUT_DIR ${DESIGN_NAME}_preview_serial.stil] -format stil -replace -serial -first 0 -last 9
write_patterns [file join $OUTPUT_DIR ${DESIGN_NAME}_full_parallel.stil] -format stil -replace -parallel
write_patterns [file join $OUTPUT_DIR ${DESIGN_NAME}_shift_only.stil] -format stil -replace -serial -first 0 -last 0
write_patterns [file join $OUTPUT_DIR ${DESIGN_NAME}_full.wgl] -format wgl -replace

# fault summary와 raw fault list를 모두 남긴다.
report_faults -summary > [file join $REPORT_DIR ${DESIGN_NAME}_sa_faults.tmax]
report_faults -all > [file join $REPORT_DIR ${DESIGN_NAME}_sa_all_faults.tmax]
write_faults [file join $REPORT_DIR ${DESIGN_NAME}.faults_all.rpt] -all -replace
write_faults [file join $REPORT_DIR ${DESIGN_NAME}.faults_all_collapsed.rpt] -all -collapsed -replace
write_faults [file join $REPORT_DIR ${DESIGN_NAME}.faults_all_uncollapsed.rpt] -all -uncollapsed -replace

# 검출 실패 fault는 클래스별로 나눠서 확인한다.
analyze_faults -class UD -verbose > [file join $REPORT_DIR ${DESIGN_NAME}.faults_UD.rpt]
analyze_faults -class AU -verbose > [file join $REPORT_DIR ${DESIGN_NAME}.faults_AU.rpt]
analyze_faults -class ND -verbose > [file join $REPORT_DIR ${DESIGN_NAME}.faults_ND.rpt]

# 구조 보고서는 coverage 해석에 필요한 것만 남긴다.
report_summaries primitives faults patterns memory > [file join $REPORT_DIR ${DESIGN_NAME}.faults.rpt]
report_scan_chains > [file join $REPORT_DIR ${DESIGN_NAME}.scan_chains.rpt]
report_scan_cells -all > [file join $REPORT_DIR ${DESIGN_NAME}.scan_cells.rpt]
report_scan_cells -all -verbose > [file join $REPORT_DIR ${DESIGN_NAME}_scan_cells.verbose.rpt]
report_nonscan_cells -all > [file join $REPORT_DIR ${DESIGN_NAME}.nonscan_cells.rpt]
report_feedback_paths -all > [file join $REPORT_DIR ${DESIGN_NAME}.feedback_paths.rpt]
report_pi_constraints > [file join $REPORT_DIR ${DESIGN_NAME}.constraints.rpt]
report_po_masks > [file join $REPORT_DIR ${DESIGN_NAME}.po_masks.rpt]
report_capture_masks > [file join $REPORT_DIR ${DESIGN_NAME}.capture_masks.rpt]
report_fault -level 16 64 -all -verbose > [file join $REPORT_DIR ${DESIGN_NAME}.coverage_level_16.rpt]
report_lockup_latches -gated_clocking -latch_based_balanced -pipeline > [file join $REPORT_DIR ${DESIGN_NAME}_lockup_latches.rpt]

# 마지막에도 요약을 남기고 정상 종료한다.
report_settings
report_summaries patterns faults memory_usage cpu_usage
exit
