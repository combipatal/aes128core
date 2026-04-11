#!/bin/csh -f
set script_dir = `dirname $0`
set base_dir = `cd ${script_dir}/.. && pwd`
cd ${base_dir}

set default_cases = ( default_nist ext_zero ext_ecb_nist )
set cases = ( $default_cases )
if ($?case_name) then
  if ( "$case_name" == "all" ) then
    set cases = ( $default_cases )
  else
    set cases = ( $case_name )
  endif
endif

mkdir -p ./2_output
mkdir -p ./3_log
mkdir -p ./4_report
setenv VCS_ARCH linux64
if ($?LD_LIBRARY_PATH) then
  setenv LD_LIBRARY_PATH "${VCS_HOME}/linux64/lib:${LD_LIBRARY_PATH}"
else
  setenv LD_LIBRARY_PATH "${VCS_HOME}/linux64/lib"
endif

foreach active_case ( $cases )
  set case_out = ./2_output/${active_case}
  set case_report = ./4_report/${active_case}
  set wave_file = ${case_out}/wave/${active_case}.vcd

  mkdir -p ${case_out}
  mkdir -p ${case_out}/wave
  mkdir -p ${case_report}

  vcs -full64 -Mdir=${case_out}/csrc -f 0_script/vcs_opts.f -f 0_script/filelist.f -top tb_top_mcu_pll_sram_multiclk_soc -o ${case_out}/simv -l ./3_log/${active_case}_compile.log
  if ($status != 0) then
    exit $status
  endif

  ${case_out}/simv +CASE=${active_case} +SUMMARY=${case_report}/summary.log +WAVE=${wave_file} -l ./3_log/${active_case}_run.log
  if ($status != 0) then
    exit $status
  endif
end

rm -f ./ucli.key
exit $status
