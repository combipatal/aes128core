#!/bin/csh -f

# 기본 합성 버전과 FM 결과 폴더 이름을 환경변수로 제어한다.
if ( ! $?ver ) setenv ver 4_15_8ns_topo_ss
if ( ! $?lib_corner ) setenv lib_corner ss
if ( ! $?fm_ver ) setenv fm_ver r2n_${ver}

if ( ! -f ../2_synthesis/2_output/${ver}/mapped/soc_gate.v ) then
    echo "Missing synthesis netlist: ../2_synthesis/2_output/${ver}/mapped/soc_gate.v"
    exit 1
endif

# FM 결과물 저장 경로를 미리 만들어서 실행 중 경로 오류를 막는다.
mkdir -p 2_output/${fm_ver}
mkdir -p 3_log
mkdir -p 4_report/${fm_ver}

# pre-DFT FM용 Tcl을 실행하고 콘솔 출력은 로그로도 남긴다.
fm_shell -64 -f 0_script/FM_r2n_script.tcl | tee 3_log/${fm_ver}.log
