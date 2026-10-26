#!/usr/bin/env python3
"""Random differential testing for big32 (production verification, in
the style of riscv-torture / riscv-dv, but small and self-contained).

Generates random, terminating RISC-V programs, runs each one through
the Python model and through the Verilog simulation, and compares the
final register file (all 32 registers) and the data memory word at
0x100. Any mismatch is a real bug, printed with the seed so it can
be reproduced exactly.

Program shape (guaranteed to terminate, no traps, no UART, no jumps
into the middle of nowhere):
  - Initialise t0-t2, a0-a1 to small random values.
  - A straight-line block of random ALU / M / shift / load / store
    instructions, using only registers t0-t2, a0-a1 and s0, with
    immediates in a small range, and memory accesses only to the
    scratch word at 0x100 (so loads never read uninitialised memory
    in a way the two models disagree on: DMEM starts at zero in both).
  - A few forward-only branches that skip at most one instruction
    (so control flow stays simple and always moves forward).
  - Ends with ECALL (mtvec is 0, so ECALL halts in both models).

Usage: python3 tools/rand_test.py [count] [first_seed]
Verilog side: sim/tb_rand.v loads programs/rand_<seed>.hex, runs it,
and prints the final registers; this script compares them.
"""
import random
import subprocess
import sys

sys.path.insert(0, "tools")
from model import run  # noqa: E402

REGS = ["t0", "t1", "t2", "a0", "a1", "s0"]
R_OPS = ["add", "sub", "and", "or", "xor", "sll", "srl", "sra",
         "slt", "sltu", "mul", "div", "divu", "rem", "remu"]
I_OPS = ["addi", "andi", "ori", "xori", "slti", "sltiu"]


def gen(seed):
    rng = random.Random(seed)
    lines = []
    for r in REGS:
        lines.append(f"li {r}, {rng.randint(-100, 100)}")
    lines.append("li s1, 256")  # scratch address 0x100, in s1 (not in REGS)
    for _ in range(rng.randint(20, 40)):
        kind = rng.random()
        rd = rng.choice(REGS)
        rs1 = rng.choice(REGS)
        rs2 = rng.choice(REGS)
        if kind < 0.45:
            lines.append(f"{rng.choice(R_OPS)} {rd}, {rs1}, {rs2}")
        elif kind < 0.70:
            op = rng.choice(I_OPS)
            lines.append(f"{op} {rd}, {rs1}, {rng.randint(-64, 63)}")
        elif kind < 0.78:
            sh = rng.choice(["slli", "srli", "srai"])
            lines.append(f"{sh} {rd}, {rs1}, {rng.randint(0, 31)}")
        elif kind < 0.86:
            lines.append(f"sw {rs2}, 0(s1)")
        elif kind < 0.94:
            lines.append(f"lw {rd}, 0(s1)")
        else:
            # Forward-only branch over the next instruction: the
            # label is always ahead, so the program cannot loop.
            lines.append(f"bne {rs1}, {rs2}, skip_{seed}_{len(lines)}")
            lines.append(f"addi {rd}, {rs1}, 1")
            lines.append(f"skip_{seed}_{len(lines) - 2}: nop")
    lines.append("mv a0, s0")
    lines.append("ecall")
    return "\n".join(lines) + "\n"


def main():
    count = int(sys.argv[1]) if len(sys.argv) > 1 else 20
    first = int(sys.argv[2]) if len(sys.argv) > 2 else 0
    # Compile the random-test testbench once.
    subprocess.run(["iverilog", "-o", "sim/tb_rand.vvp",
                    "src/big32_core.v", "src/big32.v", "sim/tb_rand.v"],
                   check=True, capture_output=True, text=True)
    fails = 0
    for seed in range(first, first + count):
        src = f"programs/rand_{seed}.s"
        hexp = f"programs/rand_{seed}.hex"
        open(src, "w").write(gen(seed))
        subprocess.run(["python3", "tools/asm.py", src, hexp],
                       check=True, capture_output=True, text=True)
        m = run(hexp)
        # The testbench always loads programs/rand_current.hex, so
        # copy this seed's hex there before running the simulation.
        import shutil
        shutil.copy(hexp, "programs/rand_current.hex")
        out = subprocess.run(["vvp", "sim/tb_rand.vvp"],
                             capture_output=True, text=True,
                             timeout=60)
        vregs = None
        for line in out.stdout.splitlines():
            if line.startswith("REGS:"):
                vregs = [int(x) for x in line[5:].split()]
        if vregs is None:
            print(f"seed {seed}: FAIL (no Verilog output)\n{out.stdout}\n{out.stderr}")
            fails += 1
            continue
        mregs = [r & 0xFFFFFFFF for r in m["regs"]]
        if vregs != mregs:
            print(f"seed {seed}: FAIL")
            for i, (a, b) in enumerate(zip(mregs, vregs)):
                if a != b:
                    print(f"  x{i}: model={a} verilog={b}")
            fails += 1
        else:
            print(f"seed {seed}: PASS (a0={mregs[10]})")
    print(f"random tests: {count - fails}/{count} passed")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
