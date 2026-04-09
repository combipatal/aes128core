#!/bin/csh -f
# edit

#module load syn/2018.06-SP4

#setenv work_path /slowfs/dgscratch1/asic/ASIC_Project/1_FrontEnd/2_Synthesis
setenv tool_path /tools/synopsys/syn/W-2024.09-SP5-5
#setenv tool_path /global/apps/syn_2018.06-SP4

set path = (. $tool_path/bin $path)

alias g 'gvim'
