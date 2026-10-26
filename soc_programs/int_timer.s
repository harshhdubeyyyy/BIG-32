# Phase 2 test: CLINT timer interrupt.
# Main sets mtimecmp = mtime + 500, enables MTIE + MIE, and polls
# a counter at 0x8000 until it reaches 5. The handler increments
# the counter and advances mtimecmp by 1000 each time, then mrets.
# Expected on halt: a0 = 5, RAM[0x8000] = 5.
        li sp, 0x80000
        la t0, trap_handler
        csrw mtvec, t0
        li t0, 0x200BFF8
        lw t1, 0(t0)
        addi t1, t1, 500
        li t0, 0x2004000
        sw t1, 0(t0)
        li t0, 128
        csrw mie, t0
        li t0, 8
        csrw mstatus, t0
        li s0, 0x8000
        li s1, 5
main_loop:
        lw t0, 0(s0)
        blt t0, s1, main_loop
        li t0, 8
        csrc mstatus, t0
        lw a0, 0(s0)
        csrw mtvec, zero
        ecall
# Handlers must save/restore every register they touch: the
# interrupted instruction (here the blt after the polling lw)
# reads registers the handler would otherwise clobber, and mepc
# correctly points back at it.
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
        addi t1, t1, 1000
        li t0, 0x2004000
        sw t1, 0(t0)
        lw t0, 0(sp)
        lw t1, 4(sp)
        lw t2, 8(sp)
        addi sp, sp, 12
        mret
