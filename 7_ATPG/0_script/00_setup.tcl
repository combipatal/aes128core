################################################################################
# 00_setup.tcl
# - Collect environment variables from run.csh.
# - Build readable path variables once at the top.
################################################################################

sh date

# Result version name for this ATPG run.
set ver [getenv ver]

# Input DFT version name.
set input_ver [getenv input_ver]

# ATPG top module name.
set DESIGN_NAME [getenv top]

# Final gate-level netlist for ATPG.
set NETLIST [getenv netlist]

# SPF file that describes scan chain connectivity and test protocol.
set SPF_FILE [getenv spf]

# ATPG directory = current working directory because run.csh launches tmax here.
set ATPG_DIR [pwd]

# Project root is one level above 6_ATPG.
set PROJECT_ROOT [file normalize [file join $ATPG_DIR ..]]

# Reference helper model directory from DC_LAB_3.
set REF_TMAX_MODEL_DIR [file normalize [file join $PROJECT_ROOT .. DC_LAB_3 4_ATPG tmax_model]]

# Standard-cell ATPG simulation model files.
set LIB_RVT [file normalize [file join $PROJECT_ROOT SAED32_EDK lib stdcell_rvt verilog saed32nm.tv]]
set LIB_HVT [file normalize [file join $PROJECT_ROOT SAED32_EDK lib stdcell_hvt verilog saed32nm_hvt.tv]]
set LIB_LVT [file normalize [file join $PROJECT_ROOT SAED32_EDK lib stdcell_lvt verilog saed32nm_lvt.tv]]

# IO / PLL / SRAM ATPG simulation model files.
set LIB_IO  [file normalize [file join $PROJECT_ROOT SAED32_EDK lib io_std verilog saed32nm_io_fc.tv]]
set LIB_PLL [file normalize [file join $PROJECT_ROOT SAED32_EDK lib pll verilog PLL.v]]
set LIB_SRAM [file normalize [file join $PROJECT_ROOT SAED32_EDK lib sram verilog saed32sram.tv]]

# Common helper model reused from the reference ATPG project.
set LIB_COMMON [file normalize [file join $REF_TMAX_MODEL_DIR common.v]]

# Main ATPG log file.
set LOG_FILE [file normalize [file join $ATPG_DIR 3_log $ver tmax.log]]

# Save expert-level tool messages into a dedicated log file.
set_messages -replace -log $LOG_FILE -level expert

puts "ATPG version     : $ver"
puts "Input DFT ver    : $input_ver"
puts "Top design       : $DESIGN_NAME"
puts "Netlist          : $NETLIST"
puts "SPF              : $SPF_FILE"
