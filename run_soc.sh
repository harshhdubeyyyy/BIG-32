#!/bin/bash
# Phase 2/3 runner: SOC tests + Phase 1 regression.
# - Compiles the SOC testbench (does NOT touch the v7 files).
# - Runs the SOC expected-value checks (tools/soc_check.py).
# - Re-runs the Phase 1 pipe suite (./run_pipe.sh) as regression.
# Run from the big32 directory: ./run_soc.sh [soc-test ...]
# With test arguments, only those SOC tests run, but the Phase 1
# regression still runs in full.
set -e
cd "$(dirname "$0")"
mkdir -p soc_hex
iverilog -o sim/tb_soc.vvp src/big32_core_pipe.v src/big32_soc.v sim/tb_soc.v
python3 tools/soc_check.py "$@"
./run_pipe.sh
