# Phase 3 test (c): page faults, delegated to S.
# Tables: identity mapping only (VA 0..0xFFFF). S loads from
# unmapped VA 0x60000000 -> load page fault (13, tval VA),
# handler counts, stores stval, and skips the load (sepc+4).
# S then jumps (jalr) to unmapped VA 0x70000000 -> instruction
# page fault (12, tval VA), handler counts, stores stval, and
# sets sepc to `resume`. Resume reads the fault count (2) into
# a0 and ECALLs to the M handler, which halts.
# Expected: a0=2, RAM[0x8104]=2, RAM[0x8108]=0x60000000,
# RAM[0x810c]=0x70000000, halted.
        li sp, 0x80000
        la t0, m_handler
        csrw mtvec, t0
        la t0, s_handler
        csrw stvec, t0
        li t0, 0x3000
        csrw medeleg, t0
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
        li t0, 0x60000000
        lw t1, 0(t0)
        li t0, 0x70000000
        jalr ra, 0(t0)
resume:
        li t0, 0x8104
        lw a0, 0(t0)
        ecall
s_handler:
        addi sp, sp, -12
        sw t0, 0(sp)
        sw t1, 4(sp)
        sw t2, 8(sp)
        csrr t0, scause
        li t1, 13
        beq t0, t1, is_loadfault
        li t1, 12
        beq t0, t1, is_fetchfault
        j s_halt
is_loadfault:
        csrr t0, stval
        li t1, 0x8108
        sw t0, 0(t1)
        li t1, 0x8104
        lw t2, 0(t1)
        addi t2, t2, 1
        sw t2, 0(t1)
        csrr t0, sepc
        addi t0, t0, 4
        csrw sepc, t0
        j s_ret
is_fetchfault:
        csrr t0, stval
        li t1, 0x810c
        sw t0, 0(t1)
        li t1, 0x8104
        lw t2, 0(t1)
        addi t2, t2, 1
        sw t2, 0(t1)
        la t0, resume
        csrw sepc, t0
        j s_ret
s_ret:
        lw t0, 0(sp)
        lw t1, 4(sp)
        lw t2, 8(sp)
        addi sp, sp, 12
        sret
s_halt:
        lw t0, 0(sp)
        lw t1, 4(sp)
        lw t2, 8(sp)
        addi sp, sp, 12
        mret
