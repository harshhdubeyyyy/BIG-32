#!/bin/bash
# Phase 4 runner: OS boot check + full Phase 2/3 + Phase 1 regression.
# - Compiles the SOC testbench (does NOT touch the v7 files).
# - Runs the OS boot transcript check (tools/os_check.py, which
#   builds the firmware/kernel/user image first).
# - Re-runs ./run_soc.sh (SOC 11/11 + pipe 16/16 + random) as
#   regression.
# Run from the big32 directory: ./run_os.sh
set -e
cd "$(dirname "$0")"
mkdir -p soc_hex
iverilog -o sim/tb_soc.vvp src/big32_core_pipe.v src/big32_soc.v sim/tb_soc.v
python3 tools/os_check.py
./run_soc.sh
