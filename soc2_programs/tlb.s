# Phase 5 TLB test (S-mode, via the SBI firmware).
# Entry from firmware at 0x80001000, a0=hartid, a1=DTB (ignored).
# Page tables: L1 at PA 0x80010000, L0 at PA 0x80011000.
#   L1[0x200] = identity superpage for VA 0x80000000 (code/stack).
#   L1[0x100] -> L0 table for the 0x40000000 test region.
#   L0[0] VA 0x40000000 -> PA 0x80030000 (data1)
#   L0[1] VA 0x40001000 -> PA 0x80031000 (data2)
#   L0[2] VA 0x40002000 -> PA 0x80011000 (the L0 table itself)
#   L1[0x101] = superpage VA 0x40400000 -> PA 0x80000000
#   (touched word at VA 0x40420000 -> PA 0x80020000, so the
#   test fits in a 1 MiB RAM)
# Checks: two 4KB translations, one superpage translation, a
# PTE change WITHOUT sfence must NOT take effect (stale TLB
# entry), and the same change WITH sfence MUST take effect.
# s0 = fail count at SRST shutdown (checker: s0 == 0).
start:
    li sp, 0x8000F000
    li s0, 0
    la t0, handler
    csrw stvec, t0
    # --- bare stores: test data (satp MODE=0 still) ---
    li t0, 0x80030000
    li t1, 0x12345678
    sw t1, 0(t0)
    li t0, 0x80031000
    li t1, 0xDEADBEEF
    sw t1, 0(t0)
    li t0, 0x80020000
    li t1, 0x55555555
    sw t1, 0(t0)
    li t0, 0x80032000
    li t1, 0xAAAAAAAA
    sw t1, 0(t0)
    # --- build tables ---
    li t0, 0x80010000
    li t2, 0x80010800
    li t1, 0x2000000F
    sw t1, 0(t2)        # L1[0x200] identity superpage
    li t1, 0x20004401
    sw t1, 0x400(t0)    # L1[0x100] -> L0 table
    li t2, 0x80010404
    li t1, 0x2000000F
    sw t1, 0(t2)        # L1[0x101] superpage -> 0x80000000
    li t0, 0x80011000
    li t1, 0x2000C00F
    sw t1, 0(t0)        # L0[0] -> 0x80030000
    li t1, 0x2000C40F
    sw t1, 4(t0)        # L0[1] -> 0x80031000
    li t1, 0x2000440F
    sw t1, 8(t0)        # L0[2] -> table page itself
    # --- enable translation ---
    li t0, 0x80080010
    csrw satp, t0
    sfence.vma
    # --- check 1: VA 0x40000000 -> 0x12345678 ---
    li t1, 0x40000000
    lw t2, 0(t1)
    li t3, 0x12345678
    beq t2, t3, ok1
    addi s0, s0, 1
ok1:
    # --- check 2: VA 0x40001000 -> 0xDEADBEEF ---
    li t1, 0x40001000
    lw t2, 0(t1)
    li t3, 0xDEADBEEF
    beq t2, t3, ok2
    addi s0, s0, 1
ok2:
    # --- check 3: superpage VA 0x40420000 -> 0x55555555 ---
    li t1, 0x40420000
    lw t2, 0(t1)
    li t3, 0x55555555
    beq t2, t3, ok3
    addi s0, s0, 1
ok3:
    # --- repoint L0[0] to 0x80032000, WITHOUT sfence ---
    li t1, 0x40002000
    li t2, 0x2000C80F
    sw t2, 0(t1)
    li t1, 0x40000000
    lw t2, 0(t1)
    li t3, 0x12345678
    beq t2, t3, ok4
    addi s0, s0, 1
ok4:
    # --- same load AFTER sfence: new translation ---
    sfence.vma
    li t1, 0x40000000
    lw t2, 0(t1)
    li t3, 0xAAAAAAAA
    beq t2, t3, ok5
    addi s0, s0, 1
ok5:
    # --- other entry unaffected by the sfence ---
    li t1, 0x40001000
    lw t2, 0(t1)
    li t3, 0xDEADBEEF
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
    # Unexpected trap: count it, skip the faulting instruction.
    addi s0, s0, 1
    csrr t0, sepc
    addi t0, t0, 4
    csrw sepc, t0
    sret
