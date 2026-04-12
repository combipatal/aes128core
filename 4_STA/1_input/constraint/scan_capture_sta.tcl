set_case_analysis 0 [get_ports scan_en]
set_case_analysis 1 [get_ports test_mode]

set_input_delay -clock ref_clk -max 1.0 [get_ports rst_n]
set_input_delay -clock ref_clk -min 0.2 [get_ports rst_n]
set_input_delay -clock ref_clk -max 1.0 [get_ports scan_in]
set_input_delay -clock ref_clk -min 0.2 [get_ports scan_in]
set_output_delay -clock ref_clk -max 1.0 [get_ports scan_out]
set_output_delay -clock ref_clk -min 0.2 [get_ports scan_out]
