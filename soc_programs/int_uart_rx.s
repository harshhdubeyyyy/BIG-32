# Phase 2 test: UART RX interrupt (routed through the external
# line, code 11). The testbench injects bytes 'A', 'B', 'C'.
# The handler reads the RX data register (popping one byte),
# adds it to a sum at 0x8004 and increments a count at 0x8000.
# Expected on halt: a0 = 65+66+67 = 198, RAM[0x8000] = 3.
        li sp, 0x80000
        la t0, trap_handler
        csrw mtvec, t0
        li t0, 2048
        csrw mie, t0
        li t0, 8
        csrw mstatus, t0
        li s0, 0x8000
        li s1, 3
main_loop:
        lw t0, 0(s0)
        blt t0, s1, main_loop
        li t0, 8
        csrc mstatus, t0
        lw a0, 4(s0)
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
        li t0, 0x10000008
        lw t1, 0(t0)
        beq t1, zero, ext_only
        li t0, 0x10000004
        lw t1, 0(t0)
        li t0, 0x8000
        lw t2, 0(t0)
        addi t2, t2, 1
        sw t2, 0(t0)
        lw t2, 4(t0)
        add t2, t2, t1
        sw t2, 4(t0)
        lw t0, 0(sp)
        lw t1, 4(sp)
        lw t2, 8(sp)
        addi sp, sp, 12
        mret
ext_only:
        li t0, 0x8000
        lw t2, 8(t0)
        addi t2, t2, 1
        sw t2, 8(t0)
        lw t0, 0(sp)
        lw t1, 4(sp)
        lw t2, 8(sp)
        addi sp, sp, 12
        mret
