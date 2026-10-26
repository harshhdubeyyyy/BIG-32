# 64-bit CLINT timer test (M-mode, bare, on soc2). a0 = fail count.
# CLINT: mtimecmp 0x02004000 (lo/hi), mtime 0x0200BFF8 (lo/hi).
start:
    li sp, 0x80010000
    li s0, 0
    li s1, 0            # timer handler count
    la t1, handler
    csrw mtvec, t1
    li t1, 0x80
    csrw mie, t1        # MTIE
    li t1, 0x8
    csrw mstatus, t1    # MIE
    # Readback: write mtimecmp = 0x123456789ABCDEF0, read it back.
    li t0, 0x02004000
    li t1, 0x9ABCDEF0
    sw t1, 0(t0)
    li t1, 0x12345678
    sw t1, 4(t0)
    lw t1, 0(t0)
    li t2, 0x9ABCDEF0
    bne t1, t2, fail
    lw t1, 4(t0)
    li t2, 0x12345678
    bne t1, t2, fail
    # Set mtime near the 32-bit boundary and mtimecmp = 2^32.
    li t0, 0x0200BFF8
    li t1, 0xFFFFFFF0
    sw t1, 0(t0)
    sw x0, 4(t0)        # mtime high = 0
    li t0, 0x02004000
    sw x0, 0(t0)        # cmp lo = 0
    li t1, 1
    sw t1, 4(t0)        # cmp hi = 1 -> cmp = 0x100000000
    # Wait for the timer interrupt (mtime crosses 2^32 in 16 cycles).
    li t2, 5000
wait1:
    addi t2, t2, -1
    bne t2, x0, wait1
    li t1, 1
    bne s1, t1, fail
    # mtime high word must now be 1 (it crossed the boundary).
    li t0, 0x0200BFF8
    lw t1, 4(t0)
    li t2, 1
    bne t1, t2, fail
    j done
fail:
    addi s0, s0, 1
done:
    mv a0, s0
    csrw mtvec, x0      # clear handler so ecall halts
    ecall

handler:
    addi sp, sp, -8
    sw t0, 0(sp)
    addi s1, s1, 1
    # Stop the timer: mtimecmp = all-ones (far future).
    li t0, 0x02004000
    li t1, -1
    sw t1, 0(t0)
    sw t1, 4(t0)
    lw t0, 0(sp)
    addi sp, sp, 8
    mret
