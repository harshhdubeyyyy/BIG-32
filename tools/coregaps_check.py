#!/usr/bin/env python3
"""Phase 5 core-gaps checker (TLB, A/D, misaligned, IPI).

Builds each S-mode test with the SBI firmware (tools/build_smode.py),
runs it on the soc2 Verilog top (sim/tb_soc2.vvp, compiled by
run_soc2.sh), and checks halted == 1 and s0 (regs[8]) == 0.
Usage (from the big32 directory):
  python3 tools/coregaps_check.py [test ...]
With no arguments, runs all core-gaps tests.
"""
import subprocess
import sys

TESTS = ["tlb", "ad", "misalign", "ipi"]


def run_one(name):
    r = subprocess.run(["python3", "tools/build_smode.py",
                        f"soc2_programs/{name}.s",
                        f"soc2_hex/{name}_img.hex"],
                       capture_output=True, text=True)
    if r.returncode != 0:
        return f"{name}: BUILD FAIL\n{r.stdout}{r.stderr}"
    out = subprocess.run(
        ["vvp", "sim/tb_soc2.vvp", f"+HEX=soc2_hex/{name}_img.hex"],
        capture_output=True, text=True, timeout=300)
    regs = cycles = halted = None
    for line in out.stdout.splitlines():
        if line.startswith("CYCLES:"):
            cycles = int(line[7:])
        elif line.startswith("HALTED:"):
            halted = int(line[7:])
        elif line.startswith("REGS:"):
            regs = [int(x) for x in line[5:].split()]
    if regs is None or halted is None:
        return (f"{name}: NO RESULT (vvp output: "
                f"{out.stdout[:400]!r} {out.stderr[:400]!r})")
    ok = (halted == 1) and (regs[8] == 0)
    return (f"{name}: {'PASS' if ok else 'FAIL'} "
            f"(halted={halted}, s0={regs[8]}, a0={regs[10]}, "
            f"cycles={cycles})")


def main():
    names = sys.argv[1:] or TESTS
    bad = 0
    for name in names:
        if name not in TESTS:
            print(f"{name}: unknown test (choices: {', '.join(TESTS)})")
            bad += 1
            continue
        line = run_one(name)
        print(line)
        if "PASS" not in line:
            bad += 1
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
