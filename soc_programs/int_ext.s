# Phase 2 test: external interrupt line. The testbench pulses
# ext_irq for 20 cycles; the handler increments a counter at
# 0x8000 once. Expected on halt: a0 = 1, RAM[0x8000] = 1.
        li sp, 0x80000
        la t0, trap_handler
        csrw mtvec, t0
        li t0, 2048
        csrw mie, t0
        li t0, 8
        csrw mstatus, t0
        li s0, 0x8000
        li s1, 1
main_loop:
        lw t0, 0(s0)
        blt t0, s1, main_loop
        li t0, 8
        csrc mstatus, t0
        lw a0, 0(s0)
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
        lw t0, 0(sp)
        lw t1, 4(sp)
        lw t2, 8(sp)
        addi sp, sp, 12
        mret
