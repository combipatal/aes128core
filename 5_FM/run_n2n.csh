#!/bin/csh -f

# 기본 reference/implementation 버전과 FM 결과 폴더 이름을 환경변수로 제어한다.
if ( ! $?ref_ver ) setenv ref_ver 4_15_8ns_ff
if ( ! $?impl_ver ) setenv impl_ver 4_15_8ns_ff_holdfix_tcl6
if ( ! $?lib_corner ) setenv lib_corner ff
if ( ! $?fm_ver ) setenv fm_ver n2n_${impl_ver}

if ( ! -f ../2_synthesis/2_output/${ref_ver}/mapped/soc_gate.v ) then
    echo "Missing synthesis reference netlist: ../2_synthesis/2_output/${ref_ver}/mapped/soc_gate.v"
    exit 1
endif

if ( ! -f ../3_DFT/2_output/${impl_ver}/aes_128_internal.v ) then
    echo "Missing DFT implementation netlist: ../3_DFT/2_output/${impl_ver}/aes_128_internal.v"
    exit 1
endif

# FM 결과물 저장 경로를 미리 만들어서 실행 중 경로 오류를 막는다.
mkdir -p 2_output/${fm_ver}
mkdir -p 3_log
mkdir -p 4_report/${fm_ver}

# post-DFT FM용 Tcl을 실행하고 콘솔 출력은 로그로도 남긴다.
fm_shell -64 -f 0_script/n2n/FM_n2n_script.tcl | tee 3_log/${fm_ver}.log
