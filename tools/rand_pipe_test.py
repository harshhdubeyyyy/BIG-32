#!/usr/bin/env python3
"""Hazard-heavy random differential testing for the pipelined core.

Like tools/rand_test.py (v7 single-cycle), but the generator is
built to stress the pipeline: dependent ALU chains (forwarding),
loads whose result is used by the very next instruction (load-use
stall + MEM->EX forward), loads feeding branches and store data,
forward-only branches, jal/ret calls to forward subroutines,
div/rem (multi-cycle divider, incl. division by zero), AMO and
LR/SC pairs on the scratch word, and back-to-back CSR writes/reads
of mscratch. Programs always terminate (no backward jumps, no
traps, no UART stores) and use only scratch memory at 0x100..0x10c
plus the register pool below (s1 holds the scratch base 256).

Each seed is run through the Python model and the pipelined
Verilog top (sim/tb_pipe.vvp); the full 32-register file and the
scratch words are compared.

Usage (from the big32 directory):
  python3 tools/rand_pipe_test.py [count] [first_seed]
Files: programs/rand_pipe_<seed>.s/.hex (new names; v7 random
files are untouched). The testbench must already be compiled
(see run_pipe.sh).
"""
import random
import subprocess
import sys

sys.path.insert(0, "tools")
from model import run  # noqa: E402

POOL = ["t0", "t1", "t2", "a0", "a1", "a2", "s0"]
R_OPS = ["add", "sub", "and", "or", "xor", "sll", "srl", "sra",
         "slt", "sltu", "mul", "mulh", "mulhu"]
I_OPS = ["addi", "andi", "ori", "xori", "slti", "sltiu"]
DIV_OPS = ["div", "divu", "rem", "remu"]
OFFS = [0, 4, 8, 12]


def gen(seed):
    rng = random.Random(seed)
    lines = []
    for r in POOL:
        lines.append(f"li {r}, {rng.randint(-100, 100)}")
    lines.append("li s1, 256")
    nsubs = rng.randint(1, 2)
    sub_labels = [f"sub_{seed}_{k}" for k in range(nsubs)]
    used_subs = set()
    last_rd = None
    pending = None  # register whose fresh value the next op must use
    n = rng.randint(30, 50)
    for k in range(n):
        kind = rng.random()
        rd = rng.choice(POOL)
        rs1 = pending if pending is not None else rng.choice(POOL)
        rs2 = rng.choice(POOL)
        pend = pending  # fresh load result the next op must consume
        pending = None
        if kind < 0.28:
            # Dependent ALU chain: use last_rd as rs1 when available.
            if last_rd is not None:
                rs1 = last_rd
            lines.append(f"{rng.choice(R_OPS)} {rd}, {rs1}, {rs2}")
            last_rd = rd
        elif kind < 0.42:
            lines.append(f"{rng.choice(I_OPS)} {rd}, {rs1}, {rng.randint(-64, 63)}")
            last_rd = rd
        elif kind < 0.48:
            sh = rng.choice(["slli", "srli", "srai"])
            lines.append(f"{sh} {rd}, {rs1}, {rng.randint(0, 31)}")
            last_rd = rd
        elif kind < 0.58:
            # Store to scratch; data is the pending load result when
            # there is one (load-use via store data), else random.
            data = pend if pend is not None else rs2
            lines.append(f"{rng.choice(['sw', 'sh', 'sb'])} {data}, {rng.choice(OFFS)}(s1)")
        elif kind < 0.70:
            # Load from scratch; the NEXT op must use its result.
            op = rng.choice(["lw", "lb", "lh", "lbu", "lhu"])
            lines.append(f"{op} {rd}, {rng.choice(OFFS)}(s1)")
            pending = rd
            last_rd = rd
        elif kind < 0.78:
            lines.append(f"{rng.choice(DIV_OPS)} {rd}, {rs1}, {rs2}")
            last_rd = rd
        elif kind < 0.83:
            # AMO on the scratch word at 0x100.
            lines.append(f"amoadd.w {rd}, {rs2}, (s1)")
            last_rd = rd
        elif kind < 0.87:
            # LR/SC pair: lr, bump, sc. Deterministic in both models.
            lines.append(f"lr.w {rd}, (s1)")
            lines.append(f"addi {rd}, {rd}, 1")
            lines.append(f"sc.w {rs2}, {rd}, (s1)")
            last_rd = rs2
        elif kind < 0.91:
            # Back-to-back CSR write then read of mscratch.
            lines.append(f"csrrw {rd}, mscratch, {rs1}")
            lines.append(f"csrrs {rs2}, mscratch, zero")
            last_rd = rs2
        elif kind < 0.96:
            # Forward-only branch over one instruction.
            lbl = f"skip_{seed}_{k}"
            lines.append(f"{rng.choice(['beq', 'bne', 'blt', 'bge'])} {rs1}, {rs2}, {lbl}")
            lines.append(f"addi {rd}, {rs1}, 1")
            lines.append(f"{lbl}: nop")
            last_rd = rd
        else:
            # jal to a forward subroutine (each sub ends with ret).
            lbl = rng.choice(sub_labels)
            lines.append(f"jal ra, {lbl}")
            used_subs.add(lbl)
            last_rd = None
    lines.append("j end_main")
    for lbl in sub_labels:
        lines.append(f"{lbl}:")
        for _ in range(rng.randint(2, 4)):
            rd = rng.choice(POOL)
            lines.append(f"{rng.choice(R_OPS)} {rd}, {rng.choice(POOL)}, {rng.choice(POOL)}")
        lines.append("ret")
    lines.append("end_main:")
    lines.append("mv a0, s0")
    lines.append("ecall")
    return "\n".join(lines) + "\n"


def parse_pipe(hexp):
    out = subprocess.run(["vvp", "sim/tb_pipe.vvp", f"+HEX={hexp}"],
                         capture_output=True, text=True, timeout=120)
    regs = cycles = halted = dmem = None
    uart = []
    for line in out.stdout.splitlines():
        if line.startswith("REGS:"):
            regs = [int(x) for x in line[5:].split()]
        elif line.startswith("CYCLES:"):
            cycles = int(line[7:])
        elif line.startswith("HALTED:"):
            halted = int(line[7:])
        elif line.startswith("DMEM:"):
            dmem = [int(x) for x in line[5:].split()]
        elif line.startswith("WARNING:") or "$finish called" in line:
            continue
        else:
            uart.append(line)
    return regs, cycles, halted, dmem, uart, out.stdout, out.stderr


def main():
    count = int(sys.argv[1]) if len(sys.argv) > 1 else 50
    first = int(sys.argv[2]) if len(sys.argv) > 2 else 0
    fails = 0
    for seed in range(first, first + count):
        src = f"programs/rand_pipe_{seed}.s"
        hexp = f"programs/rand_pipe_{seed}.hex"
        open(src, "w").write(gen(seed))
        subprocess.run(["python3", "tools/asm.py", src, hexp],
                       check=True, capture_output=True, text=True)
        m = run(hexp)
        mregs = [r & 0xFFFFFFFF for r in m["regs"]]
        mdmem = []
        for base in (0x100, 0x104, 0x108, 0x10C):
            mdmem.append(m["dmem"][base] | (m["dmem"][base + 1] << 8) |
                         (m["dmem"][base + 2] << 16) | (m["dmem"][base + 3] << 24))
        vregs, cycles, halted, dmem, uart, so, se = parse_pipe(hexp)
        problems = []
        if vregs is None:
            problems.append(f"no Verilog output\n{so}\n{se}")
        else:
            if not halted:
                problems.append("did not halt")
            if vregs != mregs:
                for i, (a, b) in enumerate(zip(mregs, vregs)):
                    if a != b:
                        problems.append(f"x{i}: model={a} verilog={b}")
            if dmem != mdmem:
                problems.append(f"dmem: model={mdmem} verilog={dmem}")
            if uart:
                problems.append(f"unexpected uart: {uart!r}")
        if problems:
            print(f"seed {seed}: FAIL ({'; '.join(problems)})")
            fails += 1
        else:
            print(f"seed {seed}: PASS (a0={mregs[10]}, cycles={cycles})")
    print(f"random pipe tests: {count - fails}/{count} passed")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
