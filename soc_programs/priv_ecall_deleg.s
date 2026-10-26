# Phase 3 test (a, delegated): U-mode ECALL with medeleg[8]=1.
# M sets stvec/mtvec, delegates U-ECALL to S, and mrets to U.
# The S handler counts entries at 0x8104, returns past the ECALL
# via sepc+4/sret; the U program stores 42 at 0x8000, then ECALLs
# again with a0=0xBEEF, which the S handler turns into a halt
# (mret in S mode is illegal, trapping to the M handler, which
# clears mtvec and ECALLs to halt).
# Expected: RAM[0x8000]=42, RAM[0x8104]=2 (two S entries), halted.
        li sp, 0x80000
        la t0, s_handler
        csrw stvec, t0
        la t0, m_handler
        csrw mtvec, t0
        li t0, 256
        csrw medeleg, t0
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
s_handler:
        csrr t0, scause
        li t1, 8
        bne t0, t1, s_halt
        li t1, 0x8104
        lw t2, 0(t1)
        addi t2, t2, 1
        sw t2, 0(t1)
        li t1, 0xBEEF
        beq a0, t1, s_halt
        csrr t0, sepc
        addi t0, t0, 4
        csrw sepc, t0
        sret
s_halt:
        mret
m_handler:
        csrw mtvec, zero
        ecall
