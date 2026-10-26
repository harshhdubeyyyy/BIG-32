#!/usr/bin/env python3
"""SOC differential/expected-value checks for Phases 2 and 3.

For each SOC test program:
  - assemble soc_programs/<name>.s into soc_hex/<name>.hex
    (tools/soc_asm.py, so asm.py itself is untouched),
  - run the SOC Verilog top (sim/tb_soc.vvp, +HEX=... plus the
    test's extra plusargs for RX injection / external pulses),
  - compare halted, a0, selected RAM words (tb_soc prints RAM
    words at 0x8000, 0x8100, 0x8104, 0x8108, 0x810c, 0x22000 in
    that order), and the UART transcript against expectations.

Usage (from the big32 directory):
  python3 tools/soc_check.py [test ...]
With no arguments, all tests run. The testbench must already be
compiled: see run_soc.sh (it compiles it first).
"""
import os
import subprocess
import sys

# RAM indices in tb_soc's RAM line: 0=0x8000, 1=0x8100, 2=0x8104,
# 3=0x8108, 4=0x810c, 5=0x22000.
TESTS = {
    "int_timer": {"a0": 5, "ram": {0: 5}, "args": []},
    "int_uart_rx": {"a0": 198, "ram": {0: 3},
                    "args": ["+RXFILE=soc_programs/rx_abc.txt",
                             "+RXSTART=600", "+RXPERIOD=600"]},
    "int_div": {"a0": 14285700, "ram": {0: 1}, "args": []},
    # 5-cycle pulse: the external line is level-sensitive, so a
    # pulse longer than the handler (~15 cycles) legitimately
    # re-interrupts and counts twice; the short pulse tests one
    # clean entry + mret return.
    "int_ext": {"a0": 1, "ram": {0: 1},
                "args": ["+EXTAT=800", "+EXTLEN=5"]},
    "priv_ecall_deleg": {"a0": 48879, "ram": {0: 42, 2: 2}, "args": []},
    "priv_ecall_m": {"a0": 48879, "ram": {0: 42, 2: 2}, "args": []},
    "mmu_basic": {"a0": 12346, "ram": {1: 12346}, "uart": "OK\n",
                  "args": []},
    "mmu_fault": {"a0": 2, "ram": {2: 2, 3: 1610612736, 4: 1879048192},
                  "args": []},
    "mmu_perm": {"a0": 48879, "ram": {1: 77, 2: 2, 5: 1}, "args": []},
    "int_vectored": {"a0": 2, "ram": {0: 2}, "args": []},
    "mmu_cross": {"a0": 1144201745, "ram": {1: 1144201745}, "args": []},
}


def run_soc(hexp, args):
    out = subprocess.run(["vvp", "sim/tb_soc.vvp", f"+HEX={hexp}"] + args,
                         capture_output=True, text=True, timeout=120)
    regs = cycles = halted = ram = None
    uart_lines = []
    for line in out.stdout.splitlines():
        if line.startswith("REGS:"):
            regs = [int(x) for x in line[5:].split()]
        elif line.startswith("CYCLES:"):
            cycles = int(line[7:])
        elif line.startswith("HALTED:"):
            halted = int(line[7:])
        elif line.startswith("RAM:"):
            ram = [int(x) for x in line[4:].split()]
        elif line.startswith("WARNING:") or "$finish called" in line:
            continue
        else:
            uart_lines.append(line)
    uart = "".join(l + "\n" for l in uart_lines)
    return regs, cycles, halted, ram, uart, out.stdout, out.stderr


def main():
    names = sys.argv[1:] or list(TESTS)
    os.makedirs("soc_hex", exist_ok=True)
    fails = 0
    for name in names:
        t = TESTS[name]
        hexp = f"soc_hex/{name}.hex"
        r = subprocess.run(["python3", "tools/soc_asm.py",
                            f"soc_programs/{name}.s", hexp],
                           capture_output=True, text=True)
        if r.returncode != 0:
            print(f"{name:16s} FAIL: assemble failed\n{r.stdout}{r.stderr}")
            fails += 1
            continue
        regs, cycles, halted, ram, uart, so, se = run_soc(hexp, t["args"])
        problems = []
        if regs is None:
            problems.append(f"no Verilog output\n{so}\n{se}")
        else:
            if not halted:
                problems.append("did not halt")
            if "a0" in t and regs[10] != t["a0"]:
                problems.append(f"a0={regs[10]} expected {t['a0']}")
            for idx, want in t.get("ram", {}).items():
                if ram[idx] != want:
                    problems.append(f"RAM[{idx}]={ram[idx]} expected {want}")
            if "uart" in t and uart != t["uart"]:
                problems.append(f"uart={uart!r} expected {t['uart']!r}")
        if problems:
            fails += 1
            print(f"{name:16s} FAIL: {'; '.join(problems)} (cycles={cycles})")
        else:
            print(f"{name:16s} PASS (a0={regs[10]}, cycles={cycles})")
    print(f"soc checks: {len(names) - fails}/{len(names)} passed")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
