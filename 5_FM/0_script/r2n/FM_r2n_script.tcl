# 현재 실행 버전과 report/output 경로를 먼저 변수로 고정한다.
set ver $env(ver)
set fm_ver $env(fm_ver)
set curr_dir [pwd]
set REPORTS ${curr_dir}/4_report/${fm_ver}
set OUTPUTS ${curr_dir}/2_output/${fm_ver}
set TOP_MODULE "top_mcu_pll_sram_multiclk_soc"
set lib_corner "ff"
if {[info exists env(lib_corner)]} {
    set lib_corner $env(lib_corner)
}

# r2n에서는 RTL을 reference로, 합성 gate를 implementation으로 비교한다.
set rtl_dir ../0_rtl
set implement_design_path ../2_synthesis/2_output/${ver}/mapped
set svf_path ../2_synthesis/default.svf
set edk_root ../SAED32_EDK

# report와 saved session 디렉터리를 미리 만들어둔다.
file mkdir $REPORTS
file mkdir $OUTPUTS

# 이전 세션의 container/guidance/constant를 지워 새 비교를 깨끗하게 시작한다.
remove_container r
remove_container i
remove_guidance
remove_constant -all
remove_black_box -all
remove_user_match -all
remove_dont_verify_point -all
remove_library -all

# FM 해석 옵션을 지정해 black-box, clock gating, mismatch 메시지 동작을 정리한다.
set synopsys_auto_setup true
set hdlin_error_on_mismatch_message false
set hdlin_warning_on_mismatch_message {FMR_ELAB-147 FMR_ELAB-116 FMR_ELAB-115}
set hdlin_unresolved_modules black_box
set verification_clock_gate_reverse_gating true
set verification_failing_point_limit 1000
set verification_timeout_limit 02:00:00
set verification_run_analyze_points true
set svf_presto_parameter_naming true
set verification_ignore_unmatched_implementation_blackbox_input true
set verification_inversion_push false
set fm_enable_new_fne true
set hdlin_enable_vpp true
set hdlin_vrlg_std 2001
set verification_set_undriven_signals synthesis

# Standard cell / SRAM / PLL 라이브러리와 RTL 탐색 경로를 설정한다.
set search_path ". \
    ${edk_root}/lib/stdcell_rvt/db_nldm \
    ${edk_root}/lib/stdcell_hvt/db_nldm \
    ${edk_root}/lib/stdcell_lvt/db_nldm \
    ${edk_root}/lib/io_std/db_nldm \
    ${edk_root}/lib/sram/db_nldm \
    ${edk_root}/lib/pll/db_nldm \
    ${rtl_dir}"

# 합성에 사용한 db 라이브러리를 읽어 gate-level cell을 해석 가능하게 만든다.
if {$lib_corner == "ff"} {
    read_db saed32rvt_ff1p16v125c.db
    read_db saed32hvt_ff1p16v125c.db
    read_db saed32lvt_ff1p16v125c.db
    read_db saed32io_fc_ff1p16v125c_2p75v.db
    read_db saed32pll_ff1p16v125c_2p75v.db
    read_db saed32sram_ff1p16v125c.db
} else {
    read_db saed32rvt_ss0p95v125c.db
    read_db saed32hvt_ss0p95v125c.db
    read_db saed32lvt_ss0p95v125c.db
    read_db saed32io_fc_ss0p95v125c_2p25v.db
    read_db saed32pll_ss0p95v125c_2p25v.db
    read_db saed32sram_ss0p95v125c.db
}

# DC에서 생성한 SVF를 읽어 RTL과 gate 간 매칭 힌트를 제공한다.
set_svf ${svf_path}

# reference 쪽에는 RTL 전체를 읽고 top을 지정한다.
read_verilog -r -libname WORK {\
    ../0_rtl/PLL_bb_for_syn.v \
    ../0_rtl/aes128_core.v \
    ../0_rtl/aes_sbox.v \
    ../0_rtl/cdc_toggle_sync.v \
    ../0_rtl/clk_div2_toggle.v \
    ../0_rtl/crc32_byte.v \
    ../0_rtl/icg_latch.v \
    ../0_rtl/soc_ctrl_multiclk_soc.v \
    ../0_rtl/sram_wrap_1rw1024x8.v \
    ../0_rtl/top_mcu_pll_sram_multiclk_soc.v \
    ../0_rtl/uart_rx.v \
    ../0_rtl/uart_tx.v \
}
set_top r:/WORK/${TOP_MODULE}

# implementation 쪽에는 합성된 mapped gate netlist를 읽고 top을 지정한다.
read_verilog -i -libname WORK ${implement_design_path}/soc_gate.v
set_top i:/WORK/${TOP_MODULE}

# scan/test 입력을 functional mode로 고정해 pre-DFT 비교 기준을 맞춘다.
set_constant -type port r:/WORK/${TOP_MODULE}/scan_en 0
set_constant -type port r:/WORK/${TOP_MODULE}/test_mode 0
set_constant -type port r:/WORK/${TOP_MODULE}/scan_in 0
set_constant -type port i:/WORK/${TOP_MODULE}/scan_en 0
set_constant -type port i:/WORK/${TOP_MODULE}/test_mode 0
set_constant -type port i:/WORK/${TOP_MODULE}/scan_in 0

# 먼저 구조 매칭을 수행하고 unmatched point 리포트를 남긴다.
match
report_unmatched_point > ${REPORTS}/unmatched_points_post_matching.rpt
report_user_matches > ${REPORTS}/user_matches_post_matching.rpt

# verify는 매칭된 point들이 실제로 등가인지 증명하는 핵심 단계다.
if {[verify]} {
    puts "\nFM PASS: r2n equivalence verified for $TOP_MODULE (ver=$ver)\n"
} else {
    puts "\nFM FAIL: r2n equivalence failed for $TOP_MODULE (ver=$ver)\n"
}

# 실패 원인 분석용 기본 report들을 남겨 다음 디버깅에 바로 쓰게 한다.
report_failing_point > ${REPORTS}/failing_points.rpt
report_aborted_point > ${REPORTS}/aborted_points.rpt
report_unverified_point > ${REPORTS}/unverified_points.rpt
report_black_box > ${REPORTS}/black_box.rpt
report_constants > ${REPORTS}/constants.rpt
report_dont_verify_points > ${REPORTS}/dont_verify_points.rpt

# 현재 FM 상태를 saved_session으로 저장해 나중에 이어서 볼 수 있게 한다.
save_session -replace ${OUTPUTS}/saved_session
exit
