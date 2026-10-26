# Phase 3 test (a, not delegated): U-mode ECALL with
# medeleg=0, so the trap goes to M with cause 8 (the origin
# mode's code, not 11). The M handler counts entries at 0x8104,
# returns past the ECALL via mepc+4/mret; the U program stores
# 42 at 0x8000, then ECALLs again with a0=0xBEEF, which the M
# handler turns into a halt (clear mtvec, ECALL).
# Expected: RAM[0x8000]=42, RAM[0x8104]=2, halted.
        li sp, 0x80000
        la t0, m_handler
        csrw mtvec, t0
        csrw medeleg, zero
        la t0, u_code
        csrw mepc, t0
        csrw mstatus, zero
        mret
u_code:
        ecall
        li s0, 0x8000
        li a0, 42
        sw a0, 0(s0)
        li a0, 0xBEEF
        ecall
m_handler:
        csrr t0, mcause
        li t1, 8
        bne t0, t1, m_halt
        li t1, 0x8104
        lw t2, 0(t1)
        addi t2, t2, 1
        sw t2, 0(t1)
        li t1, 0xBEEF
        beq a0, t1, m_halt
        csrr t0, mepc
        addi t0, t0, 4
        csrw mepc, t0
        mret
m_halt:
        csrw mtvec, zero
        ecall
