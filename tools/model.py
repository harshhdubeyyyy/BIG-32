#!/usr/bin/env python3
"""Python behavioural model of big32 v3 — cross-checks the Verilog by
running the same hex program. Usage: python3 model.py program.hex

Semantics mirror src/big32.v exactly: single-cycle, 32 registers (x0 = 0),
16KB instruction memory (PC byte address, index PC[13:2]), 64KB data
memory (addresses modulo 64KB), RV32IMAC (word atomics only), M-mode
CSRs, ECALL/EBREAK trap to mtvec when mtvec is non-zero and halt
otherwise, UART MMIO at 0x10000000 (TX), 0x10000004 (RX, returns -1),
0x10000008 (status, returns 0). Unknown opcodes are NOP, matching
the Verilog default.

Phase E addition (timer interrupts, model-only — the Verilog has no
CLINT yet): mtime at 0x10000010 and mtimecmp at 0x10000018 (32-bit
low halves, read/write; mtime advances once per executed step).
mip.MTIP (bit 7) is level-sensitive: 1 while mtime >= mtimecmp.
When mtvec is non-zero, mstatus.MIE is set, mie.MTIE is set, and
MTIP is pending, the model traps to mtvec with mcause 0x80000007
before fetching the next instruction. Trap entry saves MIE into
MPIE and clears MIE (ECALL/EBREAK too, matching real hardware);
mret restores MIE from MPIE and sets MPIE. The kernel clears the
pending level by programming mtimecmp past mtime before mret.
"""
import sys

MASK32 = 0xFFFFFFFF


def s32(x):
    x &= MASK32
    return x - 0x100000000 if x >= 0x80000000 else x


def sext(x, bits):
    if x & (1 << (bits - 1)):
        x -= 1 << bits
    return x


def run(hexfile, trace=False):
    imem = [int(l.strip(), 16) for l in open(hexfile) if l.strip()]
    imem += [0] * (4096 - len(imem))
    dmem = bytearray(65536)
    regs = [0] * 32
    # Sparse CSR file, matching the Verilog v4, plus Phase E timer CSRs.
    # Reads of unimplemented CSRs return 0, writes are ignored.
    # mhartid (0xF14) is read-only 0 and is not stored. mip (0x344) is
    # NOT stored: MTIP is computed from mtime/mtimecmp on every read,
    # and writes to it are ignored (MTIP is read-only in hardware).
    csrs = {0x300: 0, 0x304: 0, 0x305: 0, 0x340: 0, 0x341: 0, 0x342: 0,
            0x343: 0}
    mtime = 0
    mtimecmp = MASK32
    reservation_valid = False
    reservation_addr = 0
    uart = bytearray()
    pc = 0
    halted = False
    steps = 0

    def trap_entry(mcause):
        # MPIE <- MIE, MIE <- 0; mepc/mcause set; jump to mtvec.
        old_ms = csrs[0x300]
        csrs[0x300] = ((old_ms & ~0x88) | ((old_ms & 0x8) << 4)) & MASK32
        csrs[0x341] = pc
        csrs[0x342] = mcause
        csrs[0x343] = 0
        return csrs[0x305] & ~3

    def load_word(a):
        a &= 0xFFFF
        return (dmem[a] | (dmem[(a + 1) & 0xFFFF] << 8) |
                (dmem[(a + 2) & 0xFFFF] << 16) | (dmem[(a + 3) & 0xFFFF] << 24))

    def store_word(a, val):
        a &= 0xFFFF
        for k in range(4):
            dmem[(a + k) & 0xFFFF] = (val >> (8 * k)) & 0xFF

    while not halted and steps < 1000000:
        # Timer interrupt delivery, before fetch: level-sensitive MTIP,
        # gated on mtvec set, mstatus.MIE (bit 3) and mie.MTIE (bit 7).
        if (csrs[0x305] != 0 and (csrs[0x300] & 0x8) and
                (csrs[0x304] & 0x80) and mtime >= mtimecmp):
            pc = trap_entry(0x80000007)
        instr = imem[(pc >> 2) & 0xFFF]
        opcode = instr & 0x7F
        rd = (instr >> 7) & 0x1F
        funct3 = (instr >> 12) & 0x7
        rs1 = (instr >> 15) & 0x1F
        rs2 = (instr >> 20) & 0x1F
        funct7 = (instr >> 25) & 0x7F
        imm_i = sext((instr >> 20) & 0xFFF, 12)
        imm_s = sext(((instr >> 25) << 5) | ((instr >> 7) & 0x1F), 12)
        imm_b = sext((((instr >> 31) & 1) << 12) | (((instr >> 7) & 1) << 11) |
                     (((instr >> 25) & 0x3F) << 5) | (((instr >> 8) & 0xF) << 1), 13)
        imm_u = instr & 0xFFFFF000
        imm_j = sext((((instr >> 31) & 1) << 20) | (((instr >> 12) & 0xFF) << 12) |
                     (((instr >> 20) & 1) << 11) | (((instr >> 21) & 0x3FF) << 1), 21)
        v1 = regs[rs1]
        v2 = regs[rs2]
        if trace:
            print(f"pc={pc:4d} instr={instr:08x} op={opcode:07b} rd=x{rd} "
                  f"rs1=x{rs1}({v1}) rs2=x{rs2}({v2})")
        npc = (pc + 4) & MASK32
        wb = None
        if opcode == 0x33:  # R-type (I + M)
            key = (funct7, funct3)
            if key == (0x00, 0x0):
                wb = (v1 + v2) & MASK32
            elif key == (0x20, 0x0):
                wb = (v1 - v2) & MASK32
            elif key == (0x00, 0x7):
                wb = v1 & v2
            elif key == (0x00, 0x6):
                wb = v1 | v2
            elif key == (0x00, 0x4):
                wb = v1 ^ v2
            elif key == (0x00, 0x1):
                wb = (v1 << (v2 & 0x1F)) & MASK32
            elif key == (0x00, 0x5):
                wb = (v1 >> (v2 & 0x1F)) & MASK32
            elif key == (0x20, 0x5):
                wb = (s32(v1) >> (v2 & 0x1F)) & MASK32
            elif key == (0x00, 0x2):
                wb = 1 if s32(v1) < s32(v2) else 0
            elif key == (0x00, 0x3):
                wb = 1 if v1 < v2 else 0
            elif key == (0x01, 0x0):
                wb = (v1 * v2) & MASK32
            elif key == (0x01, 0x1):
                wb = ((s32(v1) * s32(v2)) >> 32) & MASK32
            elif key == (0x01, 0x2):
                wb = ((s32(v1) * v2) >> 32) & MASK32
            elif key == (0x01, 0x3):
                wb = ((v1 * v2) >> 32) & MASK32
            elif key == (0x01, 0x4):
                if v2 == 0:
                    wb = MASK32
                elif s32(v1) == -2147483648 and s32(v2) == -1:
                    wb = 0x80000000
                else:
                    q = abs(s32(v1)) // abs(s32(v2))
                    wb = -q if (s32(v1) < 0) != (s32(v2) < 0) else q
            elif key == (0x01, 0x5):
                wb = MASK32 if v2 == 0 else v1 // v2
            elif key == (0x01, 0x6):
                if v2 == 0:
                    wb = v1
                elif s32(v1) == -2147483648 and s32(v2) == -1:
                    wb = 0
                else:
                    q = abs(s32(v1)) // abs(s32(v2))
                    r = abs(s32(v1)) - q * abs(s32(v2))
                    wb = -r if s32(v1) < 0 else r
            elif key == (0x01, 0x7):
                wb = v1 if v2 == 0 else v1 % v2
        elif opcode == 0x13:  # I-type ALU
            if funct3 == 0x0:
                wb = (v1 + imm_i) & MASK32
            elif funct3 == 0x7:
                wb = v1 & (imm_i & MASK32)
            elif funct3 == 0x6:
                wb = v1 | (imm_i & MASK32)
            elif funct3 == 0x4:
                wb = v1 ^ (imm_i & MASK32)
            elif funct3 == 0x2:
                wb = 1 if s32(v1) < imm_i else 0
            elif funct3 == 0x3:
                wb = 1 if v1 < (imm_i & MASK32) else 0
            elif funct3 == 0x1:
                wb = (v1 << (imm_i & 0x1F)) & MASK32
            elif funct3 == 0x5:
                if funct7 == 0x20:
                    wb = (s32(v1) >> (imm_i & 0x1F)) & MASK32
                else:
                    wb = (v1 >> (imm_i & 0x1F)) & MASK32
        elif opcode == 0x2F:  # A extension (word only)
            funct5 = (instr >> 27) & 0x1F
            old = load_word(v1)
            if funct5 == 0x02:  # lr.w
                wb = old
                reservation_valid, reservation_addr = True, v1
            elif funct5 == 0x03:  # sc.w
                if reservation_valid and reservation_addr == v1:
                    store_word(v1, v2)
                    wb = 0
                else:
                    wb = 1
                reservation_valid = False
            else:
                amo = {0x00: (old + v2) & MASK32, 0x01: v2,
                       0x04: old ^ v2, 0x08: old | v2, 0x0C: old & v2,
                       0x10: min(s32(old), s32(v2)) & MASK32,
                       0x14: max(s32(old), s32(v2)) & MASK32,
                       0x18: min(old, v2), 0x1C: max(old, v2)}.get(funct5, old)
                store_word(v1, amo)
                wb = old
                if v1 == reservation_addr:
                    reservation_valid = False
        elif opcode == 0x03:  # Loads (with UART + timer MMIO)
            full_a = (v1 + imm_i) & MASK32
            if full_a == 0x10000000:
                wb = 0
            elif full_a == 0x10000004:
                wb = MASK32
            elif full_a == 0x10000008:
                wb = 0
            elif full_a == 0x10000010:
                wb = mtime
            elif full_a == 0x10000018:
                wb = mtimecmp
            else:
                a = full_a & 0xFFFF
                if funct3 == 0x0:
                    wb = dmem[a] - 256 if dmem[a] >= 128 else dmem[a]
                elif funct3 == 0x1:
                    w = dmem[a] | (dmem[(a + 1) & 0xFFFF] << 8)
                    wb = w - 65536 if w >= 32768 else w
                elif funct3 == 0x2:
                    wb = load_word(a)
                elif funct3 == 0x4:
                    wb = dmem[a]
                elif funct3 == 0x5:
                    wb = dmem[a] | (dmem[(a + 1) & 0xFFFF] << 8)
                wb &= MASK32
        elif opcode == 0x23:  # Stores (with UART + timer MMIO)
            full_a = (v1 + imm_s) & MASK32
            if full_a == 0x10000000:
                uart.append(v2 & 0xFF)
            elif full_a in (0x10000004, 0x10000008):
                pass
            elif full_a == 0x10000010:
                mtime = v2 & MASK32
            elif full_a == 0x10000018:
                mtimecmp = v2 & MASK32
            else:
                a = full_a & 0xFFFF
                if funct3 == 0x0:
                    dmem[a] = v2 & 0xFF
                elif funct3 == 0x1:
                    dmem[a] = v2 & 0xFF
                    dmem[(a + 1) & 0xFFFF] = (v2 >> 8) & 0xFF
                elif funct3 == 0x2:
                    store_word(a, v2)
                if full_a == reservation_addr:
                    reservation_valid = False
        elif opcode == 0x63:  # Branches
            taken = {0x0: v1 == v2, 0x1: v1 != v2,
                     0x4: s32(v1) < s32(v2), 0x5: s32(v1) >= s32(v2),
                     0x6: v1 < v2, 0x7: v1 >= v2}.get(funct3, False)
            if taken:
                npc = (pc + imm_b) & MASK32
        elif opcode == 0x6F:  # JAL
            wb = (pc + 4) & MASK32
            npc = (pc + imm_j) & MASK32
        elif opcode == 0x67:  # JALR
            wb = (pc + 4) & MASK32
            npc = ((v1 + imm_i) & ~1) & MASK32
        elif opcode == 0x37:  # LUI
            wb = imm_u
        elif opcode == 0x17:  # AUIPC
            wb = (pc + imm_u) & MASK32
        elif opcode == 0x73:  # SYSTEM: CSR, mret, ECALL, EBREAK
            csr_addr = (instr >> 20) & 0xFFF
            if funct3 != 0:  # CSR instruction
                if csr_addr == 0x344:  # mip: computed MTIP, read-only
                    old = 0x80 if mtime >= mtimecmp else 0
                else:
                    old = csrs.get(csr_addr, 0)
                wb = old
                if csr_addr in csrs:  # unimplemented + mhartid + mip: ignore writes
                    uimm = rs1
                    if funct3 == 0x1:
                        csrs[csr_addr] = v1
                    elif funct3 == 0x2:
                        if rs1 != 0:
                            csrs[csr_addr] = old | v1
                    elif funct3 == 0x3:
                        if rs1 != 0:
                            csrs[csr_addr] = old & ~v1 & MASK32
                    elif funct3 == 0x5:
                        csrs[csr_addr] = uimm
                    elif funct3 == 0x6:
                        if uimm != 0:
                            csrs[csr_addr] = old | uimm
                    elif funct3 == 0x7:
                        if uimm != 0:
                            csrs[csr_addr] = old & ~uimm & MASK32
            elif csr_addr == 0x302:  # mret: MIE <- MPIE, MPIE <- 1
                npc = csrs.get(0x341, 0)
                old_ms = csrs.get(0x300, 0)
                csrs[0x300] = ((old_ms & ~0x88) |
                               ((old_ms & 0x80) >> 4) | 0x80) & MASK32
            elif csr_addr == 0x000:  # ECALL
                if csrs.get(0x305, 0) != 0:
                    npc = trap_entry(11)
                else:
                    halted = True
            elif csr_addr == 0x001:  # EBREAK
                if csrs.get(0x305, 0) != 0:
                    npc = trap_entry(3)
                else:
                    halted = True
        # else: unknown opcode -> NOP, matching the Verilog default
        if wb is not None and rd != 0:
            regs[rd] = wb & MASK32
        regs[0] = 0
        # ECALL/EBREAK that halt leave PC at the trapping instruction,
        # matching the Verilog (which sets halted without advancing PC).
        if not halted:
            pc = npc
        steps += 1
        mtime = (mtime + 1) & MASK32
    return {"a0": regs[10], "sp": regs[2], "regs": regs, "dmem": dmem,
            "halted": halted, "steps": steps, "pc": pc,
            "uart": bytes(uart), "csrs": csrs, "mtime": mtime}


if __name__ == "__main__":
    r = run(sys.argv[1], trace="-v" in sys.argv)
    print(f"halted={r['halted']} steps={r['steps']} a0={r['a0']} sp={r['sp']}")
    if r["uart"]:
        print("uart:")
        print(r["uart"].decode("utf-8", "replace"), end="")
