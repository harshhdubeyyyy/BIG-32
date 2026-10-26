#!/usr/bin/env python3
"""big32 assembler: RISC-V RV32I assembly -> hex file for $readmemh.

Usage: python3 asm.py program.s program.hex

Syntax per line: [label:] MNEMONIC operands   # comments start with #
Operands are comma-separated; loads/stores use offset(reg), e.g. lw a0, 0(sp).
Registers: x0-x31 and ABI names (zero, ra, sp, gp, tp, t0-t6, s0-s11, a0-a7).
Immediates: decimal, 0x hex, negative, or a label (branches/jumps only).

Supported instructions (RV32I, no M/A/C, no CSRs):
  R: add sub and or xor sll srl sra slt sltu
  I: addi andi ori xori slti sltiu slli srli srai
  Loads: lb lh lw lbu lhu   Stores: sb sh sw
  Branches: beq bne blt bge bltu bgeu
  jal jalr lui auipc ecall ebreak
Pseudos: nop, mv rd, rs, li rd, imm, j label, jr rs, ret.
li expands to addi for small immediates, else lui + addi (with the
standard +0x800 rounding, so the low part always fits in 12 bits).
"""
import re
import sys

# ABI register numbers, fixed explicitly (v4 production fix: the old
# loop-based mapping gave t3-t6 = 25-28 and s2-s11 = 16-25, which is
# NOT the RISC-V ABI. Correct: t3-t6 = 28-31, s2-s11 = 18-27.
# Internally consistent code still ran, but ABI-wrong code would not
# interoperate with a real RISC-V toolchain, so this is fixed here.)
REGS = {"zero": 0, "ra": 1, "sp": 2, "gp": 3, "tp": 4,
        "t0": 5, "t1": 6, "t2": 7, "t3": 28, "t4": 29, "t5": 30, "t6": 31,
        "s0": 8, "s1": 9, "s2": 18, "s3": 19, "s4": 20, "s5": 21,
        "s6": 22, "s7": 23, "s8": 24, "s9": 25, "s10": 26, "s11": 27,
        "a0": 10, "a1": 11, "a2": 12, "a3": 13,
        "a4": 14, "a5": 15, "a6": 16, "a7": 17}
for i in range(32):
    REGS[f"x{i}"] = i

R_OPS = {"add": (0x33, 0x0, 0x00), "sub": (0x33, 0x0, 0x20),
         "and": (0x33, 0x7, 0x00), "or": (0x33, 0x6, 0x00),
         "xor": (0x33, 0x4, 0x00), "sll": (0x33, 0x1, 0x00),
         "srl": (0x33, 0x5, 0x00), "sra": (0x33, 0x5, 0x20),
         "slt": (0x33, 0x2, 0x00), "sltu": (0x33, 0x3, 0x00),
         # M extension (funct7 = 0x01)
         "mul": (0x33, 0x0, 0x01), "mulh": (0x33, 0x1, 0x01),
         "mulhsu": (0x33, 0x2, 0x01), "mulhu": (0x33, 0x3, 0x01),
         "div": (0x33, 0x4, 0x01), "divu": (0x33, 0x5, 0x01),
         "rem": (0x33, 0x6, 0x01), "remu": (0x33, 0x7, 0x01)}
I_OPS = {"addi": (0x13, 0x0), "andi": (0x13, 0x7), "ori": (0x13, 0x6),
         "xori": (0x13, 0x4), "slti": (0x13, 0x2), "sltiu": (0x13, 0x3),
         "slli": (0x13, 0x1), "srli": (0x13, 0x5), "srai": (0x13, 0x5)}
LOADS = {"lb": 0x0, "lh": 0x1, "lw": 0x2, "lbu": 0x4, "lhu": 0x5}
STORES = {"sb": 0x0, "sh": 0x1, "sw": 0x2}
BRANCHES = {"beq": 0x0, "bne": 0x1, "blt": 0x4, "bge": 0x5,
            "bltu": 0x6, "bgeu": 0x7}


def reg(name):
    n = name.strip().lower()
    if n not in REGS:
        raise ValueError(f"unknown register: {name}")
    return REGS[n]


def num(s):
    s = s.strip()
    # Character literals: 'a' -> 97, '\n' -> 10, '\'' -> 39.
    if len(s) >= 3 and s[0] == "'" and s[-1] == "'":
        body = s[1:-1]
        if body == "\\n":
            return 10
        if body == "\\t":
            return 9
        if body == "\\'":
            return 39
        if body == "\\\\":
            return 92
        return ord(body)
    if s.lower().startswith("0x") or s.lower().startswith("-0x"):
        return int(s, 16)
    return int(s, 10)


CSRS = {"mstatus": 0x300, "mie": 0x304, "mtvec": 0x305,
        "mscratch": 0x340, "mepc": 0x341, "mcause": 0x342,
        "mtval": 0x343, "mhartid": 0xF14, "satp": 0x180,
        "sstatus": 0x100, "stvec": 0x105, "sepc": 0x141,
        "scause": 0x142, "stval": 0x143}


def csr_num(s):
    s = s.strip().lower()
    if s in CSRS:
        return CSRS[s]
    return num(s)


AMO_OPS = {"amoadd.w": 0x00, "amoswap.w": 0x01, "amoxor.w": 0x04,
            "amoor.w": 0x08, "amoand.w": 0x0C, "amomin.w": 0x10,
            "amomax.w": 0x14, "amominu.w": 0x18, "amomaxu.w": 0x1C}


def parse(text):
    lines = []
    for raw in text.splitlines():
        line = raw.split("#")[0].strip()
        if not line or line.startswith("."):
            continue
        label = None
        if ":" in line:
            label, line = line.split(":", 1)
            label = label.strip()
            line = line.strip()
            if not line:
                lines.append((label, None, []))
                continue
        # Tokenise, keeping single-quoted character literals (including
        # ' ') intact: a plain whitespace split would break ' ' apart.
        toks = re.findall(r"'(?:\\.|[^'])*'|[^\s,()]+", line)
        lines.append((label, toks[0].lower(), toks[1:]))
    return lines


def expand_pseudos(parsed):
    """Expand pseudos into real instructions. li/j/jr/ret may become
    one or two instructions, so label addresses must be computed after
    expansion — hence this runs before pass 1."""
    out = []
    for label, mnem, ops in parsed:
        if mnem is None:
            out.append((label, None, []))
            continue
        if mnem == "nop":
            out.append((label, "addi", ["x0", "x0", "0"]))
        elif mnem == "mv":
            out.append((label, "addi", [ops[0], ops[1], "0"]))
        elif mnem == "li":
            imm = num(ops[1])
            if -2048 <= imm <= 2047:
                out.append((label, "addi", [ops[0], "x0", str(imm)]))
            else:
                hi = (imm + 0x800) >> 12
                lo = imm - (hi << 12)
                out.append((label, "lui", [ops[0], str(hi)]))
                if lo:
                    out.append((None, "addi", [ops[0], ops[0], str(lo)]))
        elif mnem == "j":
            out.append((label, "jal", ["x0", ops[0]]))
        elif mnem == "jr":
            out.append((label, "jalr", ["x0", "0", ops[0]]))
        elif mnem == "ret":
            out.append((label, "jalr", ["x0", "0", "x1"]))
        elif mnem == "csrw":
            # csrw csr, rs -> csrrw x0, csr, rs
            out.append((label, "csrrw", ["x0", ops[0], ops[1]]))
        elif mnem == "csrs":
            out.append((label, "csrrs", ["x0", ops[0], ops[1]]))
        elif mnem == "csrc":
            out.append((label, "csrrc", ["x0", ops[0], ops[1]]))
        elif mnem == "csrr":
            # csrr rd, csr -> csrrs rd, csr, x0
            out.append((label, "csrrs", [ops[0], ops[1], "x0"]))
        elif mnem == "la":
            # Always two instructions (auipc + addi), so label
            # addresses stay deterministic. Assembler replaces these
            # placeholders with the real pc-relative pair.
            out.append((label, "_la_hi", [ops[0], ops[1]]))
            out.append((None, "_la_lo", [ops[0], ops[1]]))
        else:
            out.append((label, mnem, ops))
    return out


def check_range(v, lo, hi, what):
    if not lo <= v <= hi:
        raise ValueError(f"{what} {v} out of range [{lo}, {hi}]")


def enc_r(op, f3, f7, rd, rs1, rs2):
    return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def enc_i(op, f3, rd, rs1, imm):
    check_range(imm, -2048, 2047, "immediate")
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def enc_s(op, f3, rs1, rs2, imm):
    check_range(imm, -2048, 2047, "immediate")
    imm &= 0xFFF
    return ((imm >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | \
           ((imm & 0x1F) << 7) | op


def enc_b(op, f3, rs1, rs2, off):
    check_range(off, -4096, 4095, "branch offset")
    if off & 1:
        raise ValueError("branch offset must be even")
    off &= 0x1FFF
    return (((off >> 12) & 1) << 31) | (((off >> 11) & 1) << 7) | \
           (((off >> 5) & 0x3F) << 25) | (((off >> 1) & 0xF) << 8) | \
           (rs2 << 20) | (rs1 << 15) | (f3 << 12) | op


def enc_u(op, rd, imm):
    # imm here is the 20-bit upper value (already shifted out by caller
    # for lui: the caller passes the raw upper bits, not the full value)
    return ((imm & 0xFFFFF) << 12) | (rd << 7) | op


def enc_j(op, rd, off):
    check_range(off, -(1 << 20), (1 << 20) - 1, "jump offset")
    if off & 1:
        raise ValueError("jump offset must be even")
    off &= 0x1FFFFF
    return (((off >> 20) & 1) << 31) | (((off >> 12) & 0xFF) << 12) | \
           (((off >> 11) & 1) << 20) | (((off >> 1) & 0x3FF) << 21) | \
           (rd << 7) | op


def assemble(text):
    parsed = expand_pseudos(parse(text))
    labels, addr = {}, 0
    for label, mnem, _ in parsed:
        if label:
            if label in labels:
                raise ValueError(f"duplicate label: {label}")
            labels[label] = addr
        if mnem is not None:
            addr += 4
    words = []
    pc = 0
    la_offset = 0
    for _, mnem, ops in parsed:
        if mnem is None:
            continue
        if mnem == "_la_hi":
            la_offset = labels[ops[1]] - pc
            hi = (la_offset + 0x800) >> 12
            words.append(enc_u(0x17, reg(ops[0]), hi))
            pc += 4
            continue
        if mnem == "_la_lo":
            lo = la_offset - (((la_offset + 0x800) >> 12) << 12)
            words.append(enc_i(0x13, 0x0, reg(ops[0]), reg(ops[0]), lo))
            pc += 4
            continue
        if mnem in AMO_OPS:
            # ops: rd, rs2, rs1  (after splitting "(rs1)")
            f5 = AMO_OPS[mnem]
            words.append((f5 << 27) | (reg(ops[1]) << 20) | (reg(ops[2]) << 15) |
                         (0x2 << 12) | (reg(ops[0]) << 7) | 0x2F)
            pc += 4
            continue
        if mnem == "lr.w":
            # ops: rd, rs1
            words.append((0x02 << 27) | (0 << 20) | (reg(ops[1]) << 15) |
                         (0x2 << 12) | (reg(ops[0]) << 7) | 0x2F)
            pc += 4
            continue
        if mnem == "sc.w":
            # ops: rd, rs2, rs1
            words.append((0x03 << 27) | (reg(ops[1]) << 20) | (reg(ops[2]) << 15) |
                         (0x2 << 12) | (reg(ops[0]) << 7) | 0x2F)
            pc += 4
            continue
        if mnem in ("csrrw", "csrrs", "csrrc"):
            f3 = {"csrrw": 0x1, "csrrs": 0x2, "csrrc": 0x3}[mnem]
            words.append((csr_num(ops[1]) << 20) | (reg(ops[2]) << 15) |
                         (f3 << 12) | (reg(ops[0]) << 7) | 0x73)
            pc += 4
            continue
        if mnem in ("csrrwi", "csrrsi", "csrrci"):
            f3 = {"csrrwi": 0x5, "csrrsi": 0x6, "csrrci": 0x7}[mnem]
            words.append((csr_num(ops[1]) << 20) | (num(ops[2]) << 15) |
                         (f3 << 12) | (reg(ops[0]) << 7) | 0x73)
            pc += 4
            continue
        if mnem == "mret":
            words.append(0x30200073)
            pc += 4
            continue
        if mnem in R_OPS:
            op, f3, f7 = R_OPS[mnem]
            w = enc_r(op, f3, f7, reg(ops[0]), reg(ops[1]), reg(ops[2]))
        elif mnem in I_OPS:
            op, f3 = I_OPS[mnem]
            f7 = 0x20 if mnem == "srai" else 0x00
            imm = num(ops[2])
            if mnem in ("slli", "srli", "srai"):
                check_range(imm, 0, 31, "shift amount")
                w = (f7 << 25) | (imm << 20) | (reg(ops[1]) << 15) | \
                    (f3 << 12) | (reg(ops[0]) << 7) | op
            else:
                w = enc_i(op, f3, reg(ops[0]), reg(ops[1]), imm)
        elif mnem in LOADS:
            # ops: rd, offset, rs1  (after splitting "0(sp)" -> ["0", "sp"])
            w = enc_i(0x03, LOADS[mnem], reg(ops[0]), reg(ops[2]), num(ops[1]))
        elif mnem in STORES:
            # ops: rs2, offset, rs1
            w = enc_s(0x23, STORES[mnem], reg(ops[2]), reg(ops[0]), num(ops[1]))
        elif mnem in BRANCHES:
            off = labels[ops[2]] - pc
            w = enc_b(0x63, BRANCHES[mnem], reg(ops[0]), reg(ops[1]), off)
        elif mnem == "jal":
            if len(ops) == 1:
                rd, target = 1, ops[0]
            else:
                rd, target = reg(ops[0]), ops[1]
            w = enc_j(0x6F, rd, labels[target] - pc)
        elif mnem == "jalr":
            # ops: rd, offset, rs1
            w = enc_i(0x67, 0x0, reg(ops[0]), reg(ops[2]), num(ops[1]))
        elif mnem == "lui":
            w = enc_u(0x37, reg(ops[0]), num(ops[1]))
        elif mnem == "auipc":
            w = enc_u(0x17, reg(ops[0]), num(ops[1]))
        elif mnem == "ecall":
            w = 0x00000073
        elif mnem == "ebreak":
            w = 0x00100073
        else:
            raise ValueError(f"unknown mnemonic: {mnem}")
        words.append(w & 0xFFFFFFFF)
        pc += 4
    return words


def main():
    src, dst = sys.argv[1], sys.argv[2]
    words = assemble(open(src).read())
    with open(dst, "w") as fh:
        for w in words:
            fh.write(f"{w:08x}\n")
    print(f"assembled {len(words)} words -> {dst}")


if __name__ == "__main__":
    main()
