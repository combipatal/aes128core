# 현재 실행 버전과 report/output 경로를 먼저 변수로 고정한다.
set ver $env(ver)
set fm_ver $env(fm_ver)
set curr_dir [pwd]
set REPORTS ${curr_dir}/4_report/${fm_ver}
set OUTPUTS ${curr_dir}/2_output/${fm_ver}
set TOP_MODULE "top_mcu_pll_sram_multiclk_soc"

# n2n에서는 synthesis gate를 reference로, DFT netlist를 implementation으로 비교한다.
set reference_design_path ../2_synthesis/2_output/${ver}/mapped
set implement_design_path ../3_DFT/2_output/${ver}
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

# Standard cell / SRAM / PLL 라이브러리 탐색 경로를 설정한다.
set search_path ". \
    ${edk_root}/lib/stdcell_rvt/db_nldm \
    ${edk_root}/lib/stdcell_hvt/db_nldm \
    ${edk_root}/lib/stdcell_lvt/db_nldm \
    ${edk_root}/lib/io_std/db_nldm \
    ${edk_root}/lib/sram/db_nldm \
    ${edk_root}/lib/pll/db_nldm"

# gate-level netlist를 해석할 수 있도록 합성 라이브러리 db를 읽는다.
read_db saed32rvt_ss0p95v125c.db
read_db saed32hvt_ss0p95v125c.db
read_db saed32lvt_ss0p95v125c.db
read_db saed32io_fc_ss0p95v125c_2p25v.db
read_db saed32pll_ss0p95v125c_2p25v.db
read_db saed32sram_ss0p95v125c.db

# reference 쪽에는 synthesis mapped gate를 읽고 top을 지정한다.
read_verilog -r -libname WORK ${reference_design_path}/soc_gate.v
set_top r:/WORK/${TOP_MODULE}

# implementation 쪽에는 scan insertion이 끝난 DFT netlist를 읽고 top을 지정한다.
read_verilog -i -libname WORK ${implement_design_path}/aes_128_internal.v
set_top i:/WORK/${TOP_MODULE}

# post-DFT 비교에서도 functional mode 기준을 맞추기 위해 scan/test 입력을 고정한다.
set_constant -type port r:/WORK/${TOP_MODULE}/scan_en 0
set_constant -type port r:/WORK/${TOP_MODULE}/test_mode 0
set_constant -type port r:/WORK/${TOP_MODULE}/scan_in 0
set_constant -type port i:/WORK/${TOP_MODULE}/scan_en 0
set_constant -type port i:/WORK/${TOP_MODULE}/test_mode 0
set_constant -type port i:/WORK/${TOP_MODULE}/scan_in 0

# scan_out는 post-DFT에서 scan chain용 test output 성격이 강하므로 functional n2n 비교에서 제외한다.
set_dont_verify_point r:/WORK/${TOP_MODULE}/scan_out
set_dont_verify_point i:/WORK/${TOP_MODULE}/scan_out

# 먼저 구조 매칭을 수행하고 unmatched point 리포트를 남긴다.
match
report_unmatched_point > ${REPORTS}/unmatched_points_post_matching.rpt
report_user_matches > ${REPORTS}/user_matches_post_matching.rpt

# verify는 scan logic가 추가된 뒤에도 기능 등가가 유지되는지 확인한다.
if {[verify]} {
    puts "\nFM PASS: n2n equivalence verified for $TOP_MODULE (ver=$ver)\n"
} else {
    puts "\nFM FAIL: n2n equivalence failed for $TOP_MODULE (ver=$ver)\n"
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
