# Phase 2 test: vectored mtvec (MODE=01). mtvec = vec_base | 1,
# so a timer interrupt (code 7) goes to vec_base + 7*4, while
# exceptions would still go to vec_base itself. The handler at
# vec_base+28 increments the counter at 0x8000 and advances
# mtimecmp, then mrets. Main polls until the count reaches 2.
# Expected: a0=2, RAM[0x8000]=2, halted.
        li sp, 0x80000
        la t0, vec_base
        ori t0, t0, 1
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
        li s1, 2
main_loop:
        lw t0, 0(s0)
        blt t0, s1, main_loop
        li t0, 8
        csrc mstatus, t0
        lw a0, 0(s0)
        csrw mtvec, zero
        ecall
vec_base:
        nop
        nop
        nop
        nop
        nop
        nop
        nop
vec_timer:
        addi sp, sp, -12
        sw t0, 0(sp)
        sw t1, 4(sp)
        sw t2, 8(sp)
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
