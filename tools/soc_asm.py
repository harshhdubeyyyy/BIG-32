#!/usr/bin/env python3
"""SOC assembler: tools/asm.py plus the instructions Phase 2/3
SOC programs need, without modifying asm.py (a v7 file).

Added, on top of asm.py:
  sret                  -> 0x10200073
  sfence.vma [rs1, rs2]-> (0x09<<25)|(rs2<<20)|(rs1<<15)|0x73
                          (bare sfence.vma == sfence.vma x0, x0)
  .word 0x........      -> that exact word (data / raw encodings)
  CSR names mip (0x344), sie (0x104), sscratch (0x140),
  medeleg (0x302), mideleg (0x303), sip (0x144) in CSR instructions
  (asm.py already knows mstatus/mie/mtvec/mscratch/mepc/mcause/
  mtval/satp/sstatus/stvec/sepc/scause/stval, and CSR operands may
  always be given as numbers, e.g. csrw 0x344, t0).

Method: each added line is replaced, label intact, by a unique
marker instruction (lui x31, 0xA0000+index) that asm.py assembles
normally, so label addresses and li/la expansion are exactly
asm.py's. The assembled marker words are then overwritten with
the real encodings. If a marker word is not found, assembly fails
rather than silently producing a wrong program.

Usage: python3 tools/soc_asm.py program.s program.hex
"""
import re
import sys

sys.path.insert(0, "tools")
import asm  # noqa: E402

EXTRA_CSRS = {"mip": 0x344, "sie": 0x104, "sscratch": 0x140,
              "medeleg": 0x302, "mideleg": 0x303, "sip": 0x144}
MARKER_BASE = 0xA0000


def transform(text):
    """Return (transformed_text, [(marker_word, real_word), ...])."""
    out_lines = []
    patches = []
    idx = 0
    for raw in text.splitlines():
        line = raw.split("#")[0].strip()
        if not line:
            out_lines.append(raw)
            continue
        # Split off an optional label.
        label, rest = "", line
        if ":" in line:
            label, rest = line.split(":", 1)
            label = label.strip() + ": "
            rest = rest.strip()
        if not rest:
            out_lines.append(raw)
            continue
        toks = rest.split()
        mnem = toks[0].lower()
        real = None
        if mnem == "sret":
            real = 0x10200073
        elif mnem == "sfence.vma":
            ops = rest[len(toks[0]):].replace(",", " ").split()
            rs1 = asm.reg(ops[0]) if len(ops) > 0 else 0
            rs2 = asm.reg(ops[1]) if len(ops) > 1 else 0
            real = (0x09 << 25) | (rs2 << 20) | (rs1 << 15) | 0x73
        elif mnem in (".word", "word"):
            real = asm.num(toks[1])
        if real is not None:
            marker_imm = MARKER_BASE + idx
            marker_word = ((marker_imm & 0xFFFFF) << 12) | (31 << 7) | 0x37
            patches.append((marker_word, real))
            idx += 1
            out_lines.append(f"{label}lui x31, 0x{marker_imm:x}")
            continue
        # CSR name rewrite for the extra CSRs (whole-word only).
        for name, num in EXTRA_CSRS.items():
            rest = re.sub(rf"\b{name}\b", f"0x{num:x}", rest)
        out_lines.append(f"{label}{rest}")
    return "\n".join(out_lines) + "\n", patches


def main():
    src, dst = sys.argv[1], sys.argv[2]
    text = open(src).read()
    transformed, patches = transform(text)
    words = asm.assemble(transformed)
    for marker, real in patches:
        try:
            pos = words.index(marker)
        except ValueError:
            raise SystemExit(f"soc_asm: marker word {marker:08x} not found "
                             f"(internal error; program not assembled)")
        words[pos] = real & 0xFFFFFFFF
    with open(dst, "w") as fh:
        for w in words:
            fh.write(f"{w:08x}\n")
    print(f"assembled {len(words)} words -> {dst}")


if __name__ == "__main__":
    main()
