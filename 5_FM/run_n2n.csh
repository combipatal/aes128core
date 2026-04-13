#!/bin/csh -f

# 기본 DFT 버전과 FM 결과 폴더 이름을 환경변수로 제어한다.
if ( ! $?ver ) setenv ver 4_13_7p3ns
if ( ! $?fm_ver ) setenv fm_ver n2n_${ver}

# FM 결과물 저장 경로를 미리 만들어서 실행 중 경로 오류를 막는다.
mkdir -p 2_output/${fm_ver}
mkdir -p 3_log
mkdir -p 4_report/${fm_ver}

# post-DFT FM용 Tcl을 실행하고 콘솔 출력은 로그로도 남긴다.
fm_shell -64 -f 0_script/n2n/FM_n2n_script.tcl | tee 3_log/${fm_ver}.log
