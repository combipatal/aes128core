################################################################################
# 50_write_patterns.tcl
# - Save the generated patterns in a few easy-to-read formats.
################################################################################

# Use cell-level inversion reference so WGL output matches the scan netlist polarity.
set_wgl -inversion_reference cell -tester_ready

# Full serial STIL is the most common portable ATPG output.
write_patterns ./2_output/${ver}/${DESIGN_NAME}_full_serial.stil -format stil -replace -serial

# A short serial STIL is useful for quick debug and waveform inspection.
write_patterns ./2_output/${ver}/${DESIGN_NAME}_preview_serial.stil -format stil -replace -serial -first 0 -last 9

# Full parallel STIL is useful when comparing tester style options.
write_patterns ./2_output/${ver}/${DESIGN_NAME}_full_parallel.stil -format stil -replace -parallel

# Shift-only STIL is convenient when debugging scan chain movement only.
write_patterns ./2_output/${ver}/${DESIGN_NAME}_shift_only.stil -format stil -replace -serial -first 0 -last 0

# WGL is still useful in many academic / legacy tester flows.
write_patterns ./2_output/${ver}/${DESIGN_NAME}_full.wgl -format wgl -replace
