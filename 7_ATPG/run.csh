#!/bin/csh -f

# 현재 ATPG 기본 기준은 post-DFT 완료 버전이다.
if ( ! $?ver ) setenv ver 4_16_8ns_topo_ss

# ATPG 산출물 디렉터리를 먼저 만든다.
mkdir -p 2_output/${ver}
mkdir -p 3_log/${ver}
mkdir -p 4_report/${ver}

# 현재 기준 DFT netlist가 없으면 바로 중단한다.
if ( ! -e ../4_DFT/2_output/${ver}/aes_128_internal.v ) then
  echo "ERROR: DFT netlist not found -> ../4_DFT/2_output/${ver}/aes_128_internal.v"
  exit 1
endif

# 현재 기준 scan SPF가 없으면 바로 중단한다.
if ( ! -e ../4_DFT/2_output/${ver}/scan_internal.spf ) then
  echo "ERROR: scan SPF not found -> ../4_DFT/2_output/${ver}/scan_internal.spf"
  exit 1
endif

# 단일 Tcl 스크립트로 ATPG 전체 흐름을 실행한다.
tmax -64 -tcl -shell ./0_script/atpg_script.tcl |& tee 3_log/${ver}/console.log
