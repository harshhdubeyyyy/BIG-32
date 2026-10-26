# Phase 4 M-mode firmware. Runs bare at reset (priv = M, satp = 0).
# Assembled ONLY via tools/build_os.py (STRING lines + fixed layout);
# do not feed this file directly to tools/soc_asm.py.
# Layout contract (see OS_BOOT.md): firmware at PA 0x0000 (<= 0x1000
# bytes), kernel at 0x1000, user at 0x3000. Firmware never returns:
# it prints a banner, sets delegation, writes the CLINT baseline,
# and mrets to the S-mode kernel with mstatus.MPP = S, MPIE = 1.
# The M handler below is TERMINAL: it prints and halts. It is
# reached only for traps NOT delegated to S -- in this design that
# is the kernel's S-ECALL shutdown request (cause 9, deliberately
# not delegated) and any unexpected M trap.
        li sp, 0x10000
        la t0, m_handler
        csrw mtvec, t0
        li t0, 0xB9FF
        csrw medeleg, t0
        li t0, 0x888
        csrw mideleg, t0
        # CLINT baseline: mtimecmp = 0xFFFFFFFF (also the reset
        # value; written explicitly so the baseline is visible).
        li t0, 0x02004000
        li t1, -1
        sw t1, 0(t0)
        la a0, str_banner
        jal ra, fw_print_str
        la a0, str_fw_ok
        jal ra, fw_print_str
        la a0, str_deleg
        jal ra, fw_print_str
        li t0, 0x1000
        csrw mepc, t0
        li t0, 0x880
        csrw mstatus, t0
        mret
m_handler:
        # Terminal handler: borrow the M stack, print, halt.
        li sp, 0x10000
        csrr t2, mcause
        li t1, 9
        bne t2, t1, m_unexpected
        la a0, str_mhalt
        jal ra, fw_print_str
        csrw mtvec, zero
        ecall
m_unexpected:
        la a0, str_mtrap
        jal ra, fw_print_str
        csrw mtvec, zero
        ecall
fw_putc:
        li t0, 0x10000000
        sb a0, 0(t0)
        ret
fw_print_str:
        addi sp, sp, -8
        sw ra, 0(sp)
        sw t1, 4(sp)
        mv t1, a0
fw_ps_loop:
        lb t0, 0(t1)
        beq t0, zero, fw_ps_done
        mv a0, t0
        jal ra, fw_putc
        addi t1, t1, 1
        j fw_ps_loop
fw_ps_done:
        lw t1, 4(sp)
        lw ra, 0(sp)
        addi sp, sp, 8
        ret
str_banner: STRING "BIG32 OS BOOT\n"
str_fw_ok: STRING "M: firmware ok\n"
str_deleg: STRING "M: deleg medeleg=0xb9ff mideleg=0x888\n"
str_mhalt: STRING "M: halt\n"
str_mtrap: STRING "M: trap\n"
