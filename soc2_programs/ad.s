# Phase 5 A/D-bit test (S-mode, via the SBI firmware).
# VA 0x40000000 -> PA 0x80030000, PTE starts with A=0, D=0.
# A load must set A (D stays 0); a store must then set D.
# The PTE is read back through VA 0x40002000, which maps the
# L0 table page itself. s0 = fail count at SRST shutdown.
start:
    li sp, 0x8000F000
    li s0, 0
    la t0, handler
    csrw stvec, t0
    # --- bare stores: test data + tables ---
    li t0, 0x80030000
    li t1, 0x11223344
    sw t1, 0(t0)
    li t0, 0x80010000
    li t2, 0x80010800
    li t1, 0x2000000F
    sw t1, 0(t2)        # L1[0x200] identity superpage
    li t1, 0x20004401
    sw t1, 0x400(t0)    # L1[0x100] -> L0 table
    li t0, 0x80011000
    li t1, 0x2000C00F
    sw t1, 0(t0)        # L0[0] -> 0x80030000, A=0, D=0
    li t1, 0x2000440F
    sw t1, 8(t0)        # L0[2] -> table page itself
    # --- enable translation ---
    li t0, 0x80080010
    csrw satp, t0
    sfence.vma
    # --- load: value right, then PTE must show A=1, D=0 ---
    li t1, 0x40000000
    lw t2, 0(t1)
    li t3, 0x11223344
    beq t2, t3, ok1
    addi s0, s0, 1
ok1:
    li t1, 0x40002000
    lw t2, 0(t1)        # L0[0] PTE word
    andi t3, t2, 0xC0
    li t4, 0x40
    beq t3, t4, ok2
    addi s0, s0, 1
ok2:
    # --- store: value updates, then PTE must show A=1, D=1 ---
    li t1, 0x40000000
    li t2, 0x55667788
    sw t2, 0(t1)
    li t1, 0x40002000
    lw t2, 0(t1)
    andi t3, t2, 0xC0
    li t4, 0xC0
    beq t3, t4, ok3
    addi s0, s0, 1
ok3:
    # --- stored value reads back through the TLB entry ---
    li t1, 0x40000000
    lw t2, 0(t1)
    li t3, 0x55667788
    beq t2, t3, done
    addi s0, s0, 1
done:
    li a7, 0x53525354
    li a6, 0
    li a0, 0
    li a1, 0
    ecall
    j done
handler:
    addi s0, s0, 1
    csrr t0, sepc
    addi t0, t0, 4
    csrw sepc, t0
    sret
