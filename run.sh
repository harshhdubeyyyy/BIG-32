#!/bin/bash
# Build + test big32 end to end (v1). Run from the big32 directory.
set -e
cd "$(dirname "$0")"
for p in sum fib mul_loop call_demo mul_demo mulh_demo div_demo div_edge div_zero rem_zero amo_demo sc_fail csr_demo edge_cases kernel; do
  python3 tools/asm.py programs/$p.s programs/$p.hex
  python3 tools/model.py programs/$p.hex
done
cd sim
iverilog -o tb_big32.vvp ../src/big32_core.v ../src/big32.v tb_big32.v
vvp tb_big32.vvp
