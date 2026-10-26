# Phase 2 test: interrupt during division. Main enables the
# timer (first fire ~1000 cycles in) and runs 100 divisions
# (1000003 / 7 = 142857 each, ~32 cycles in EX each), so the
# timer necessarily fires while some division is in EX. The
# handler advances mtimecmp far into the future, so exactly one
# interrupt is taken, and the division in progress must still
# produce the right quotient (an interrupt that flushed EX
# mid-division would corrupt the sum).
# Expected on halt: a0 = 100 * 142857 = 14285700, RAM[0x8000] = 1.
        li sp, 0x80000
        la t0, trap_handler
        csrw mtvec, t0
        li t0, 0x200BFF8
        lw t1, 0(t0)
        addi t1, t1, 1000
        li t0, 0x2004000
        sw t1, 0(t0)
        li t0, 128
        csrw mie, t0
        li t0, 8
        csrw mstatus, t0
        li s1, 100
        li s2, 0
        li t3, 1000003
        li t4, 7
divloop:
        div t5, t3, t4
        add s2, s2, t5
        addi s1, s1, -1
        bne s1, zero, divloop
        li t0, 8
        csrc mstatus, t0
        mv a0, s2
        csrw mtvec, zero
        ecall
trap_handler:
        addi sp, sp, -12
        sw t0, 0(sp)
        sw t1, 4(sp)
        sw t2, 8(sp)
        csrr t0, mcause
        blt t0, zero, is_int
        lw t0, 0(sp)
        lw t1, 4(sp)
        lw t2, 8(sp)
        addi sp, sp, 12
        mret
is_int:
        li t0, 0x8000
        lw t1, 0(t0)
        addi t1, t1, 1
        sw t1, 0(t0)
        li t0, 0x200BFF8
        lw t1, 0(t0)
        li t2, 100000
        add t1, t1, t2
        li t0, 0x2004000
        sw t1, 0(t0)
        lw t0, 0(sp)
        lw t1, 4(sp)
        lw t2, 8(sp)
        addi sp, sp, 12
        mret
