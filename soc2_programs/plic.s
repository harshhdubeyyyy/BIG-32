# PLIC test (M-mode, bare, on soc2). a0 = fail count at halt.
# PLIC: source 1 = 16550 UART, source 2 = virtio, source 3 = ext.
# 16550 base 0x10010000, PLIC base 0x0C000000.
# RX byte 'A' (0x41) is injected by the testbench (RX2FILE).
start:
    li sp, 0x80010000
    li s0, 0            # fail count
    li s1, 0            # handler count
    # 16550: LCR 8N1, IER RDA enable.
    li t0, 0x10010000
    li t1, 0x03
    sb t1, 3(t0)        # LCR
    li t1, 0x01
    sb t1, 1(t0)        # IER = RDA
    # PLIC: priorities 1, enables M bits 1..3, threshold 2 first.
    li t0, 0x0C000000
    li t1, 1
    sw t1, 4(t0)        # prio src1
    sw t1, 8(t0)        # prio src2
    sw t1, 12(t0)       # prio src3
    li t1, 0xE
    li t3, 0x0C002000
    sw t1, 0(t3)        # enable M: bits 1,2,3
    li t1, 2
    li t3, 0x0C200000
    sw t1, 0(t3)        # threshold M = 2 (blocks prio-1 sources)
    # mtvec = handler, mie MEIE, mstatus MIE.
    la t1, handler
    csrw mtvec, t1
    li t1, 0x800
    csrw mie, t1
    li t1, 0x8
    csrw mstatus, t1
    # Wait: with threshold 2, no interrupt should arrive.
    li t2, 3000
wait1:
    addi t2, t2, -1
    bne t2, x0, wait1
    bne s1, x0, thresh_fail
    j thresh_ok
thresh_fail:
    addi s0, s0, 1
thresh_ok:
    # Lower threshold to 0: the pending UART interrupt (RX byte
    # injected at cycle 600, held in the FIFO) must now fire.
    li t3, 0x0C200000
    sw x0, 0(t3)        # threshold M = 0
    li t2, 5000
wait2:
    addi t2, t2, -1
    bne t2, x0, wait2
    li t1, 1
    bne s1, t1, count_fail
    j count_ok
count_fail:
    addi s0, s0, 1
count_ok:
    # Handler stored claim id at 0x8000F000 and RBR byte at
    # 0x8000F004; check them.
    li t0, 0x8000F000
    lw t1, 0(t0)
    li t2, 1
    bne t1, t2, claim_fail
    lw t1, 4(t0)
    li t2, 0x41
    bne t1, t2, rbr_fail
    j done
claim_fail:
    addi s0, s0, 1
    j done
rbr_fail:
    addi s0, s0, 1
done:
    mv a0, s0
    csrw mtvec, x0      # clear handler so ecall halts
    ecall

handler:
    addi sp, sp, -16
    sw t0, 0(sp)
    sw t1, 4(sp)
    sw t2, 8(sp)
    addi s1, s1, 1
    li t3, 0x0C200004
    lw t1, 0(t3)        # claim M
    li t2, 0x8000F000
    sw t1, 0(t2)
    li t0, 0x10010000
    lbu t1, 0(t0)       # RBR (pops the FIFO)
    li t2, 0x8000F000
    sw t1, 4(t2)
    li t2, 0x8000F000
    lw t1, 0(t2)        # claim id again
    li t3, 0x0C200004
    sw t1, 0(t3)        # complete
    lw t0, 0(sp)
    lw t1, 4(sp)
    lw t2, 8(sp)
    addi sp, sp, 16
    mret
