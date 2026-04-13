# 기본 메시지/리포트 설정
set sh_message_limit "500"
history keep 100
set report_default_significant_digits "4"

# 분석 기본 옵션
set auto_wire_load_selection "false"
set auto_link_disable "false"
set case_analysis_sequential_propagation "never"
set svr_keep_unconnected_nets "true"
set link_create_black_boxes "false"

# 타이밍 계산/업데이트 관련
set timing_update_status_level "high"
set timing_save_pin_arrival_and_slack "true"
set timing_enable_preset_clear_arcs "true"

# clock gating / recovery-removal check 활성
set timing_disable_recovery_removal_checks "false"
set timing_disable_clock_gating_checks "false"
set timing_clock_gating_propagate_enable "true"

# unconstrained path / CRPR 관련
set timing_report_unconstrained_paths "true"
set timing_remove_clock_reconvergence_pessimism "true"

# latch / borrowing 관련
set timing_include_available_borrow_in_slack "true"
set timing_allow_short_path_borrowing "true"
