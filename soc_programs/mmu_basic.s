# Phase 3 test (b): S-mode Sv32 page tables, translation on.
# M builds: identity mapping for VA 0..0xFFFF (root[0] ->
# table at 0x11000, 16 entries), VA 0x40000000 -> PA 0x20000
# (data page, R/W), VA 0x50000000 -> PA 0x10000000 (UART, R/W),
# stores 12345 at PA 0x20000, then mrets to S with satp =
# 0x80000010 (MODE=Sv32, root page 0x10). S loads the data page
# through VA 0x40000000, adds 1, stores 12346 at 0x8100, prints
# "OK\n" through the mapped UART VA, and ECALLs to the M
# handler (cause 9), which halts.
# Expected: a0=12346, RAM[0x8100]=12346, UART "OK\n", halted.
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
        li t1, 0x4C01
        sw t1, 0x500(t0)
        li t0, 0x12000
        li t1, 0x8007
        sw t1, 0(t0)
        li t0, 0x13000
        li t1, 0x4000007
        sw t1, 0(t0)
        li t0, 0x20000
        li t1, 12345
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
        li t0, 0x40000000
        lw t1, 0(t0)
        addi t1, t1, 1
        li t0, 0x8100
        sw t1, 0(t0)
        li t0, 0x50000000
        li a0, 'O'
        sb a0, 0(t0)
        li a0, 'K'
        sb a0, 0(t0)
        li a0, '\n'
        sb a0, 0(t0)
        li t0, 0x8100
        lw a0, 0(t0)
        ecall
