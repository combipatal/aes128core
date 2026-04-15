set_case_analysis 0 [get_ports scan_en]
set_case_analysis 1 [get_ports test_mode]

# Scan capture is closer to functional capture than scan shift.
# Keep the functional/generated clocks from synthesis SDC.
# Only remove the pure scan path and async reset from timing.
set_false_path -from [get_ports scan_in]
set_false_path -to [get_ports scan_out]
set_false_path -from [get_ports rst_n]
