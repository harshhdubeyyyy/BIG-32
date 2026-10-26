#!/usr/bin/env python3
"""Phase 4 OS boot checker.

Builds the firmware + S kernel + user image (tools/build_os.py),
runs it on the SOC Verilog top (sim/tb_soc.vvp, compiled by
run_os.sh), and compares the WHOLE UART transcript -- byte for
byte -- against the hand-computed expected transcript below, plus
halted == 1. The expected values are derived from the kernel/user
program logic, not from the Python model (which does not implement
S/U modes or the MMU): the tick count is 2 by construction (the
kernel waits for exactly 2 timer ticks, stops the timer, and the
user phase is given a 50000-cycle compare window it cannot
outlast), the sum is 1+...+10 = 55, and the faulting load reads 0
from the freshly demand-mapped zeroed page.

Usage (from the big32 directory): python3 tools/os_check.py
"""
import subprocess
import sys

EXPECTED = """\
BIG32 OS BOOT
M: firmware ok
M: deleg medeleg=0xb9ff mideleg=0x888
S: kernel start
S: pagetables ok
S: translation on
S: ticks=2
U: hello from user
U: sum=55
FAULT: cause=13 addr=0x60000000
FAULT: mapped page
U: faultval=0
U: exit=0
S: ticks=2
S: shutdown
M: halt
"""


def main():
    r = subprocess.run(["python3", "tools/build_os.py"],
                       capture_output=True, text=True)
    print(r.stdout, end="")
    if r.returncode != 0:
        print(f"os_boot FAIL: build failed\n{r.stderr}")
        return 1
    out = subprocess.run(["vvp", "sim/tb_soc.vvp",
                          "+HEX=soc_hex/os_boot.hex"],
                         capture_output=True, text=True, timeout=300)
    cycles = halted = None
    uart_lines = []
    for line in out.stdout.splitlines():
        if line.startswith("CYCLES:"):
            cycles = int(line[7:])
        elif line.startswith("HALTED:"):
            halted = int(line[7:])
        elif line.startswith(("REGS:", "RAM:")):
            continue
        elif line.startswith("WARNING:") or "$finish called" in line:
            # Testbench chatter, not UART output (same filter as
            # tools/soc_check.py).
            continue
        else:
            uart_lines.append(line)
    uart = "".join(l + "\n" for l in uart_lines)
    problems = []
    if halted != 1:
        problems.append(f"halted={halted} (expected 1)")
    if uart != EXPECTED:
        problems.append("transcript mismatch:\n"
                        f"--- expected ---\n{EXPECTED}"
                        f"--- actual ---\n{uart}")
    if cycles is None or cycles > 1000000:
        problems.append(f"cycles={cycles} (expected < 1000000)")
    if problems:
        print("os_boot FAIL: " + "\n".join(problems))
        print(f"(raw stdout follows)\n{out.stdout}\n{out.stderr}")
        return 1
    print(f"os_boot PASS (cycles={cycles})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
