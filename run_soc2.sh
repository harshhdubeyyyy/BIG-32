#!/bin/bash
# Phase 5 runner: soc2 platform tests + SBI/DTB check + full
# Phase 1-4 regression (./run_os.sh).
# Run from the big32 directory: ./run_soc2.sh [soc2-test ...]
set -e
cd "$(dirname "$0")"
mkdir -p soc2_hex
iverilog -o sim/tb_soc2.vvp src/big32_core_pipe.v src/big32_soc2.v sim/tb_soc2.v
python3 tools/soc2_check.py "$@"
python3 tools/coregaps_check.py
python3 tools/sbi_check.py
python3 tools/check_dtb.py
python3 tools/boot_check.py
./run_os.sh
