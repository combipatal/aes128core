set_case_analysis 1 [get_ports scan_en]
set_case_analysis 1 [get_ports test_mode]

# In shift mode, focus on the scan path itself.
set_input_delay -clock ref_clk -max 1.0 [get_ports scan_in]
set_input_delay -clock ref_clk -min 0.2 [get_ports scan_in]
set_output_delay -clock ref_clk -max 1.0 [get_ports scan_out]
set_output_delay -clock ref_clk -min 0.2 [get_ports scan_out]

set_false_path -from [get_ports start]
set_false_path -from [get_ports uart_rxd]
set_false_path -from [get_ports aes_vec_valid]
set_false_path -from [get_ports aes_key_ext]
set_false_path -from [get_ports aes_pt_ext]
set_false_path -from [get_ports rst_n]
