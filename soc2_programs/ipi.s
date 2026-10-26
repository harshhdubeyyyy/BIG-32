# Phase 5 SBI IPI test (S-mode, via the SBI firmware).
# Calls SBI sPI send_ipi for hart 0, then expects an S-mode
# software interrupt (mideleg bit 3 delegates it). The S
# handler counts the interrupt and clears the IPI by writing
# 0 to the soc2 IPI register via VA 0x40004000, which maps
# the device page at PA 0x10002000. s0 = fail count at SRST.
start:
    li sp, 0x8000F000
    li s0, 0
    la t0, handler
    csrw stvec, t0
    # --- build tables: identity superpage + IPI device page ---
    li t0, 0x80010000
    li t2, 0x80010800
    li t1, 0x2000000F
    sw t1, 0(t2)        # L1[0x200] identity superpage
    li t1, 0x20004401
    sw t1, 0x400(t0)    # L1[0x100] -> L0 table
    li t0, 0x80011000
    li t1, 0x4000807
    sw t1, 16(t0)       # L0[4] VA 0x40004000 -> PA 0x10002000
    # --- enable translation ---
    li t0, 0x80080010
    csrw satp, t0
    sfence.vma
    # --- enable S software interrupts ---
    li t1, 0x2
    csrw sie, t1        # SSIE
    csrs sstatus, t1    # SIE
    # --- SBI send_ipi: hart_mask=1, base=0 ---
    li a7, 0x735049
    li a6, 0
    li a0, 1
    li a1, 0
    ecall
    bne a0, x0, bad
    # --- wait for the handler to count 1 ---
    li t3, 50000
    li t5, 0x8000F108
wait:
    lw t1, 0(t5)
    li t2, 1
    beq t1, t2, done
    addi t3, t3, -1
    bne t3, x0, wait
    # timeout: no IPI arrived
    addi s0, s0, 1
    j done
bad:
    addi s0, s0, 1
done:
    li a7, 0x53525354
    li a6, 0
    li a0, 0
    li a1, 0
    ecall
    j done
handler:
    # S software interrupt: count, clear the IPI, return.
    li t0, 0x8000F108
    lw t1, 0(t0)
    addi t1, t1, 1
    sw t1, 0(t0)
    li t0, 0x40004000
    sw x0, 0(t0)        # clear IPI (level source: must clear
    sret                # before returning, or it retakes)
