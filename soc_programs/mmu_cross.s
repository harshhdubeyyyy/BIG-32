# Phase 3 test: misaligned access crossing a page boundary.
# Tables: identity (0..0xFFFF) plus VA 0x40000000 -> PA 0x20000
# (one page only; VA 0x40001000 is unmapped). Bytes at PA
# 0x20FFE..0x21001 are set to 11 22 33 44. S does an unaligned
# lw from VA 0x40000FFE: the documented behaviour is NO split
# and NO fault for the second page — the whole word is read
# from the first page's translation, continuing into the next
# physical page, giving 0x44332211. (A splitting design would
# fault here on the unmapped second page instead.)
# Expected: a0=0x44332211 (1144201745), RAM[0x8100]=same, halted.
        li sp, 0x80000
        la t0, m_handler
        csrw mtvec, t0
        li t0, 0x11000
        li t1, 16
        li t2, 0
id_loop:
        slli t3, t2, 10
        ori t3, t3, 15
        sw t3, 0(t0)
        addi t0, t0, 4
        addi t2, t2, 1
        blt t2, t1, id_loop
        li t0, 0x10000
        li t1, 0x4401
        sw t1, 0(t0)
        li t1, 0x4801
        sw t1, 0x400(t0)
        li t0, 0x12000
        li t1, 0x8007
        sw t1, 0(t0)
        li t0, 0x20FFE
        li t1, 0x11
        sb t1, 0(t0)
        li t0, 0x20FFF
        li t1, 0x22
        sb t1, 0(t0)
        li t0, 0x21000
        li t1, 0x33
        sb t1, 0(t0)
        li t0, 0x21001
        li t1, 0x44
        sb t1, 0(t0)
        la t0, s_code
        csrw mepc, t0
        li t0, 0x800
        csrw mstatus, t0
        li t0, 0x80000010
        csrw satp, t0
        mret
m_handler:
        csrw mtvec, zero
        ecall
s_code:
        li sp, 0x8000
        li t0, 0x40000FFE
        lw t1, 0(t0)
        li t0, 0x8100
        sw t1, 0(t0)
        mv a0, t1
        ecall
