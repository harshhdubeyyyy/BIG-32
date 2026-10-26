# SBI firmware (M-mode, Phase 5). Entry at RAM base (via ROM jump).
# Sets up delegation (S-ecall NOT delegated, so it lands here),
# then drops to the S-mode test at 0x80001000 with a0=hartid,
# a1=DTB address (0x80020000, loaded by the testbench).
# SBI extensions implemented:
#   Base 0x10: get_spec_version (2.0), get_impl_id ("BIG3"),
#     get_impl_version (1), probe_extension, vendor/arch/imp ids (0)
#   Legacy 0x01: console_putchar (a0 = byte)
#   TIME 0x54494D45: set_timer (a0=lo, a1=hi -> mtimecmp)
#   sPI 0x735049: send_ipi (Phase 5: real single-hart IPI via
#   the soc2 IPI register at 0x10002000; a real
#     IPI line is added with the core irq_soft step)
#   RFNC 0x52464E43: fence_i / sfence_vma (single hart: the
#     sfence executes here, so a TLB flush happens in M)
#   SRST 0x53525354: system_reset -> shutdown (clear mtvec, ecall)
# Unknown extension/FID -> SBI_ERR_INVALID_PARAM (-2).
# Handler stack: firmware stack top 0x8000E000 via mscratch swap.
entry:
    li t0, 0x8000E000
    csrw mscratch, t0
    la t1, handler
    csrw mtvec, t1
    li t1, 0xB9FF
    csrw medeleg, t1
    li t1, 0x888
    csrw mideleg, t1
    # Drop to S: MPP=S (mstatus bits 12:11 = 01), mepc=test.
    li t1, 0x80001000
    csrw mepc, t1
    li t1, 0x800
    csrw mstatus, t1
    li a0, 0
    li a1, 0x80020000
    mret

handler:
    csrrw sp, mscratch, sp
    addi sp, sp, -128
    sw ra, 0(sp)
    sw a0, 4(sp)
    sw a1, 8(sp)
    sw a2, 12(sp)
    sw a3, 16(sp)
    sw a4, 20(sp)
    sw a5, 24(sp)
    sw a6, 28(sp)
    sw a7, 32(sp)
    sw t0, 36(sp)
    sw t1, 40(sp)
    sw t2, 44(sp)
    sw t3, 48(sp)
    sw t4, 52(sp)
    sw t5, 56(sp)
    sw t6, 60(sp)
    csrr t0, mcause
    blt t0, x0, int_path
    li t1, 9
    bne t0, t1, other_trap
    # S-ecall: dispatch on a7.
    li t1, 0x10
    beq a7, t1, base_ext
    li t1, 1
    beq a7, t1, legacy_putchar
    li t1, 0x54494D45
    beq a7, t1, time_ext
    li t1, 0x735049
    beq a7, t1, spi_ext
    li t1, 0x52464E43
    beq a7, t1, rfnc_ext
    li t1, 0x53525354
    beq a7, t1, srst_ext
    li a0, -2
    li a1, 0
    j ret_path

base_ext:
    li t1, 0
    beq a6, t1, base_spec
    li t1, 1
    beq a6, t1, base_implid
    li t1, 2
    beq a6, t1, base_implver
    li t1, 3
    beq a6, t1, base_probe
    li t1, 4
    beq a6, t1, base_zero
    li t1, 5
    beq a6, t1, base_zero
    li t1, 6
    beq a6, t1, base_zero
    li a0, -2
    li a1, 0
    j ret_path
base_spec:
    li a0, 0
    li a1, 0x02000000
    j ret_path
base_implid:
    li a0, 0
    li a1, 0x42494733
    j ret_path
base_implver:
    li a0, 0
    li a1, 1
    j ret_path
base_zero:
    li a0, 0
    li a1, 0
    j ret_path
base_probe:
    mv t2, a0
    li t1, 0x10
    beq t2, t1, probe_yes
    li t1, 0x54494D45
    beq t2, t1, probe_yes
    li t1, 0x735049
    beq t2, t1, probe_yes
    li t1, 0x52464E43
    beq t2, t1, probe_yes
    li t1, 0x53525354
    beq t2, t1, probe_yes
    li a0, 0
    li a1, 0
    j ret_path
probe_yes:
    li a0, 0
    li a1, 1
    j ret_path

legacy_putchar:
    li t0, 0x10000000
    sb a0, 0(t0)
    li a0, 0
    li a1, 0
    j ret_path

time_ext:
    li t1, 0
    bne a6, t1, err_param
    li t0, 0x02004000
    sw a0, 0(t0)
    sw a1, 4(t0)
    li a0, 0
    li a1, 0
    j ret_path

spi_ext:
    li t1, 0
    bne a6, t1, err_param
    # Phase 5: real IPI, not a no-op. Single hart: set the
    # soc2 SBI IPI register (0x10002000) when the mask
    # selects hart 0: hart_mask_base == -1 (all harts), or
    # base == 0 with mask bit 0 set. The S-mode handler
    # clears it by writing 0 to the same register.
    li t0, 0x10002000
    li t1, -1
    beq a1, t1, spi_set
    li t1, 0
    bne a1, t1, spi_done
    andi t2, a0, 1
    beq t2, x0, spi_done
spi_set:
    li t2, 1
    sw t2, 0(t0)
spi_done:
    li a0, 0
    li a1, 0
    j ret_path

rfnc_ext:
    li t1, 0
    beq a6, t1, rfnc_ok
    li t1, 1
    beq a6, t1, rfnc_sfence
    li t1, 2
    beq a6, t1, rfnc_sfence
    li t1, 3
    beq a6, t1, rfnc_ok
    li t1, 4
    beq a6, t1, rfnc_ok
    li t1, 5
    beq a6, t1, rfnc_ok
    li t1, 6
    beq a6, t1, rfnc_ok
    j err_param
rfnc_sfence:
    sfence.vma
rfnc_ok:
    li a0, 0
    li a1, 0
    j ret_path

srst_ext:
    li t1, 0
    bne a6, t1, err_param
    # Shutdown: restore the original stack, clear mtvec, ecall
    # in M with mtvec==0 -> core halts.
    lw ra, 0(sp)
    lw a2, 12(sp)
    lw a3, 16(sp)
    lw a4, 20(sp)
    lw a5, 24(sp)
    lw a6, 28(sp)
    lw a7, 32(sp)
    lw t0, 36(sp)
    lw t1, 40(sp)
    lw t2, 44(sp)
    lw t3, 48(sp)
    lw t4, 52(sp)
    lw t5, 56(sp)
    lw t6, 60(sp)
    addi sp, sp, 128
    csrrw sp, mscratch, sp
    csrw mtvec, x0
    ecall
    # Unreachable if the core halts; loop defensively.
halt_loop:
    j halt_loop

err_param:
    li a0, -2
    li a1, 0
    j ret_path

other_trap:
    li t0, 0x10000000
    li t1, 0x21
    sb t1, 0(t0)        # '!' on an unexpected trap
    j halt_path

int_path:
    # Machine timer interrupt (code 7): stop the timer, mret
    # without advancing mepc (interrupts do not advance it).
    csrr t0, mcause
    li t1, 0x80000007
    bne t0, t1, halt_path
    li t0, 0x02004000
    li t1, -1
    sw t1, 0(t0)
    sw t1, 4(t0)
    j ret_int

ret_int:
    lw ra, 0(sp)
    lw a0, 4(sp)
    lw a1, 8(sp)
    lw a2, 12(sp)
    lw a3, 16(sp)
    lw a4, 20(sp)
    lw a5, 24(sp)
    lw a6, 28(sp)
    lw a7, 32(sp)
    lw t0, 36(sp)
    lw t1, 40(sp)
    lw t2, 44(sp)
    lw t3, 48(sp)
    lw t4, 52(sp)
    lw t5, 56(sp)
    lw t6, 60(sp)
    addi sp, sp, 128
    csrrw sp, mscratch, sp
    mret

ret_path:
    lw ra, 0(sp)
    lw a2, 12(sp)
    lw a3, 16(sp)
    lw a4, 20(sp)
    lw a5, 24(sp)
    lw a6, 28(sp)
    lw a7, 32(sp)
    lw t0, 36(sp)
    lw t1, 40(sp)
    lw t2, 44(sp)
    lw t3, 48(sp)
    lw t4, 52(sp)
    lw t5, 56(sp)
    lw t6, 60(sp)
    csrr t2, mepc
    addi t2, t2, 4
    csrw mepc, t2
    addi sp, sp, 128
    csrrw sp, mscratch, sp
    mret

halt_path:
    lw ra, 0(sp)
    lw a2, 12(sp)
    lw a3, 16(sp)
    lw a4, 20(sp)
    lw a5, 24(sp)
    lw a6, 28(sp)
    lw a7, 32(sp)
    lw t0, 36(sp)
    lw t1, 40(sp)
    lw t2, 44(sp)
    lw t3, 48(sp)
    lw t4, 52(sp)
    lw t5, 56(sp)
    lw t6, 60(sp)
    addi sp, sp, 128
    csrrw sp, mscratch, sp
    csrw mtvec, x0
    ecall
    j halt_loop
