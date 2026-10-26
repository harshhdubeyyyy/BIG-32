#!/bin/bash
# Phase 1 runner: re-run the whole pipelined-core test set in one command.
# - Compiles the pipelined testbench (does NOT touch the v7 files).
# - Directed set: the 15 v7 programs + pipe_hazards, model vs pipelined
#   Verilog, full register file + UART + scratch memory compared
#   (tools/pipe_check.py; programs are assembled into pipe_hex/, so
#   the existing programs/*.hex files are never overwritten).
# - Random set: 50 hazard-heavy seeds, model vs pipelined Verilog
#   (tools/rand_pipe_test.py).
# Run from the big32 directory: ./run_pipe.sh
set -e
cd "$(dirname "$0")"
mkdir -p pipe_hex
iverilog -o sim/tb_pipe.vvp src/big32_core_pipe.v src/big32_pipe.v sim/tb_pipe.v
python3 tools/pipe_check.py
python3 tools/rand_pipe_test.py 50 0
