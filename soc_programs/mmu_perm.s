# Phase 3 test (d): page permissions + SUM + U/S separation.
# Tables: identity (0..0xFFFF); VA 0x40000000 -> PA 0x20000
# (S-only page, R/W, value 111); VA 0x41000000 -> PA 0x21000
# (U page, R/W, value 77); VA 0x42000000 -> PA 0x22000 (U page
# for the U program's result); VA 0x43000000 -> PA page 0
# (U page, R/W/X: the U program itself, fetched through it).
# S loads the U page without SUM -> load fault (handler counts,
# skips); S sets SUM and retries -> 77, stored at 0x8100.
# S drops to U (sepc = U code VA, SPP=0, sret). U loads the
# S-only page -> load fault to the S handler (counts, skips,
# sret back to U). U stores 1 at 0x42000000 and ECALLs with
# a0=0xBEEF; the S handler turns that into a halt (mret in S
# is illegal -> M handler clears mtvec and ECALLs).
# The S handler swaps sp via sscratch, because it can arrive
# with the U program's stack pointer (a U-page address its own
# pushes would fault on without SUM).
# Expected: RAM[0x8100]=77, RAM[0x8104]=2, RAM[0x22000]=1,
# a0=0xBEEF (48879), halted.
        li sp, 0x80000
        la t0, m_handler
        csrw mtvec, t0
        la t0, s_handler
        csrw stvec, t0
        li t0, 0x7F00
        csrw sscratch, t0
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
        li t1, 0x4C01
        sw t1, 0x410(t0)
        li t1, 0x5001
        sw t1, 0x420(t0)
        li t1, 0x5401
        sw t1, 0x430(t0)
        li t0, 0x12000
        li t1, 0x8007
        sw t1, 0(t0)
        li t0, 0x13000
        li t1, 0x8417
        sw t1, 0(t0)
        li t0, 0x14000
        li t1, 0x8817
        sw t1, 0(t0)
        li t0, 0x15000
        li t1, 0x1F
        sw t1, 0(t0)
        li t0, 0x20000
        li t1, 111
        sw t1, 0(t0)
        li t0, 0x21000
        li t1, 77
        sw t1, 0(t0)
        li t0, 0x2000
        csrw medeleg, t0
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
        li t0, 0x41000000
        lw t1, 0(t0)
        li t0, 0x40000
        csrs sstatus, t0
        li t0, 0x41000000
        lw t1, 0(t0)
        li t0, 0x8100
        sw t1, 0(t0)
        la t0, u_code
        li t1, 0x43000000
        add t0, t0, t1
        csrw sepc, t0
        li t0, 0x100
        csrc sstatus, t0
        sret
u_code:
        li sp, 0x42000F00
        li t0, 0x40000000
        lw t1, 0(t0)
        li t0, 0x42000000
        li t1, 1
        sw t1, 0(t0)
        li a0, 0xBEEF
        ecall
s_handler:
        csrrw sp, sscratch, sp
        addi sp, sp, -12
        sw t0, 0(sp)
        sw t1, 4(sp)
        sw t2, 8(sp)
        csrr t0, scause
        li t1, 13
        beq t0, t1, is_loadfault
        li t1, 8
        beq t0, t1, is_ecall
        j s_halt
is_loadfault:
        li t1, 0x8104
        lw t2, 0(t1)
        addi t2, t2, 1
        sw t2, 0(t1)
        csrr t0, sepc
        addi t0, t0, 4
        csrw sepc, t0
        j s_ret
is_ecall:
        li t1, 0xBEEF
        beq a0, t1, s_halt
        csrr t0, sepc
        addi t0, t0, 4
        csrw sepc, t0
        j s_ret
s_ret:
        lw t0, 0(sp)
        lw t1, 4(sp)
        lw t2, 8(sp)
        addi sp, sp, 12
        csrrw sp, sscratch, sp
        sret
s_halt:
        lw t0, 0(sp)
        lw t1, 4(sp)
        lw t2, 8(sp)
        addi sp, sp, 12
        csrrw sp, sscratch, sp
        mret
