# 16550 UART test (M-mode, bare, on soc2). a0 = fail count.
# RX bytes 'B' (0x42), 'C' (0x43) injected by the testbench.
start:
    li sp, 0x80010000
    li s0, 0
    li t0, 0x10010000
    li t1, 0x03
    sb t1, 3(t0)        # LCR 8N1
    li t1, 0x55
    sb t1, 0(t0)        # THR = 'U' (captured on UART)
    # Poll LSR until DR, then check IIR with IER=0 (expect 0xC1).
poll1:
    lbu t1, 5(t0)       # LSR
    andi t1, t1, 1
    beq t1, x0, poll1
    lbu t1, 2(t0)       # IIR
    li t2, 0xC1
    bne t1, t2, fail
    # Enable RDA interrupt: IIR must become 0xC4.
    li t1, 0x01
    sb t1, 1(t0)        # IER = RDA
    lbu t1, 2(t0)       # IIR
    li t2, 0xC4
    bne t1, t2, fail
    # Read first byte, expect 'B'.
    lbu t1, 0(t0)       # RBR
    li t2, 0x42
    bne t1, t2, fail
    # Poll for second byte, expect 'C'.
poll2:
    lbu t1, 5(t0)
    andi t1, t1, 1
    beq t1, x0, poll2
    lbu t1, 0(t0)
    li t2, 0x43
    bne t1, t2, fail
    # FIFO now empty: LSR DR must be 0.
    lbu t1, 5(t0)
    andi t1, t1, 1
    bne t1, x0, fail
    j done
fail:
    addi s0, s0, 1
    # Drain the FIFO so later checks do not see stale bytes.
    li t0, 0x10010000
    lbu t1, 0(t0)
    j done
done:
    mv a0, s0
    ecall
