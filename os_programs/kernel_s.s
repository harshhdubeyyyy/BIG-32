# Phase 4 S-mode test kernel. Entry: firmware mrets here at VA 0x1000
# with satp = 0 (bare), so VA == PA until translation is enabled.
# Assembled ONLY via tools/build_os.py (STRING lines + fixed layout).
# Layout contract (see OS_BOOT.md): kernel at 0x1000, <= 0x2000 bytes
# (two pages: 0x1000 S R+X, 0x2000 S R+X); user at 0x3000.
# Scratch (VA, S R/W page 0x9000): 0x9000 ticks, 0x9004 timer
# interval, 0x9008 exit code, 0x900C external-interrupt count.
# Kernel stack: VA 0x8000 page, top 0x9000. sscratch = 0x9000.
# Helper convention: k_putc/k_print_str/k_print_int/k_print_hex use
# only t-registers, a0, ra, and the stack -- never s-registers --
# because the S handler saves only ra/t0-t6/a0-a7. k_print_str sets
# sstatus.SUM while reading, so it can print both kernel (S) and
# user (U) strings; it always clears SUM before returning.
k_entry:
        li sp, 0x9000
        li t0, 0x9000
        csrw sscratch, t0
        la t0, s_handler
        csrw stvec, t0
        # ---- Build Sv32 page tables (bare: VA == PA here) ----
        # Root at PA 0x10000 (satp PPN 0x10). L1[0] -> L0 low,
        # L1[256] -> L0 UART (VA 0x40000000), L1[320] -> L0 CLINT
        # (VA 0x50000000). L1[384] (VA 0x60000000) is left zero:
        # the user fault on it is the demand-map demo.
        li t0, 0x10000
        li t1, 0x4401
        sw t1, 0(t0)
        li t1, 0x4801
        sw t1, 1024(t0)
        li t1, 0x4C01
        sw t1, 1280(t0)
        # L0 low at PA 0x11000: firmware/kernel/user/stack/tables.
        li t0, 0x11000
        li t1, 0xB
        sw t1, 0(t0)
        li t1, 0x40B
        sw t1, 4(t0)
        li t1, 0x80B
        sw t1, 8(t0)
        li t1, 0xC1B
        sw t1, 12(t0)
        li t1, 0x1017
        sw t1, 16(t0)
        # Above, in order: VA 0x0000 firmware S R+X, VA 0x1000
        # kernel page 1 S R+X, VA 0x2000 kernel page 2 S R+X,
        # VA 0x3000 user code U R+X, VA 0x4000 user stack U R+W.
        li t1, 0x2007
        sw t1, 32(t0)
        li t1, 0x2407
        sw t1, 36(t0)
        li t1, 0x4007
        sw t1, 64(t0)
        li t1, 0x4407
        sw t1, 68(t0)
        li t1, 0x4807
        sw t1, 72(t0)
        li t1, 0x4C07
        sw t1, 76(t0)
        li t1, 0x5007
        sw t1, 80(t0)
        li t1, 0x5407
        sw t1, 84(t0)
        # L0 UART at PA 0x12000: entry 0 -> PA 0x10000000 R+W.
        # PPN(0x10000000) = 0x10000, so PTE = 0x10000<<10 | 7 =
        # 0x04000007 (seven hex digits -- NOT 0x40000007, which
        # decodes to truncated PA 0x00000000 and silently sinks
        # UART bytes into RAM[0]; found by a real Phase 4 run).
        li t0, 0x12000
        li t1, 0x04000007
        sw t1, 0(t0)
        # L0 CLINT at PA 0x13000: entry 4 -> PA 0x02004000
        # (mtimecmp), entry 11 -> PA 0x0200B000 (mtime page).
        li t0, 0x13000
        li t1, 0x801007
        sw t1, 16(t0)
        li t1, 0x802C07
        sw t1, 44(t0)
        # ---- Enable translation: satp = MODE Sv32, PPN 0x10 ----
        li t0, 0x80000010
        csrw satp, t0
        sfence.vma
        # ---- Now translated: UART VA 0x40000000, scratch 0x9000 ----
        la a0, str_kstart
        jal ra, k_print_str
        la a0, str_ptok
        jal ra, k_print_str
        la a0, str_trans
        jal ra, k_print_str
        # ---- Timer: sie = STIE|SEIE, sstatus SIE = 1 ----
        li t0, 0x220
        csrw sie, t0
        li t0, 2
        csrw sstatus, t0
        # Wait phase: interval 2000, ticks = 0, cmp = mtime + 2000.
        li t0, 0x9000
        sw zero, 0(t0)
        li t1, 2000
        sw t1, 4(t0)
        li t0, 0x5000BFF8
        lw t1, 0(t0)
        addi t1, t1, 2000
        li t0, 0x50004000
        sw t1, 0(t0)
k_wait:
        li t0, 0x9000
        lw t1, 0(t0)
        li t2, 2
        blt t1, t2, k_wait
        # Stop the timer FIRST (before any printing), so no third
        # tick can land while the tick line is being printed.
        li t0, 0x50004000
        li t1, -1
        sw t1, 0(t0)
        la a0, str_ticks
        jal ra, k_print_str
        li t0, 0x9000
        lw a0, 0(t0)
        jal ra, k_print_int
        li a0, 10
        jal ra, k_putc
        # ---- Drop to user: interval 50000, cmp = mtime + 50000.
        # The whole user phase is a few thousand cycles, so no
        # timer tick can fire there; the final tick count stays 2
        # by construction, not by luck.
        li t0, 0x9000
        li t1, 50000
        sw t1, 4(t0)
        li t0, 0x5000BFF8
        lw t1, 0(t0)
        li t2, 50000
        add t1, t1, t2
        li t0, 0x50004000
        sw t1, 0(t0)
        li t0, 0x3000
        csrw sepc, t0
        li t0, 0x9000
        csrw sscratch, t0
        li sp, 0x5000
        li t0, 0x22
        csrw sstatus, t0
        sret
k_shutdown:
        la a0, str_ticks
        jal ra, k_print_str
        li t0, 0x9000
        lw a0, 0(t0)
        jal ra, k_print_int
        li a0, 10
        jal ra, k_putc
        la a0, str_sdown
        jal ra, k_print_str
        ecall
# ---------------- S trap/interrupt handler ----------------
# Entry: swap sp with sscratch (kernel stack top), save ra,
# t0-t6, a0-a7 (64 bytes). Exit (s_ret): restore, swap back, sret.
# Timer and external interrupts, syscalls, and the demand-mapped
# page fault all return through s_ret; exit and unhandled traps
# jump to k_shutdown instead (no return to user).
s_handler:
        csrrw sp, sscratch, sp
        addi sp, sp, -64
        sw ra, 0(sp)
        sw t0, 4(sp)
        sw t1, 8(sp)
        sw t2, 12(sp)
        sw t3, 16(sp)
        sw t4, 20(sp)
        sw t5, 24(sp)
        sw t6, 28(sp)
        sw a0, 32(sp)
        sw a1, 36(sp)
        sw a2, 40(sp)
        sw a3, 44(sp)
        sw a4, 48(sp)
        sw a5, 52(sp)
        sw a6, 56(sp)
        sw a7, 60(sp)
        csrr t0, scause
        blt t0, zero, s_int
        li t1, 8
        beq t0, t1, s_syscall
        li t1, 13
        beq t0, t1, s_fault13
        j s_unhandled
s_int:
        li t1, 0x80000005
        beq t0, t1, s_timer
        li t1, 0x80000009
        beq t0, t1, s_ext
        j s_ret
s_timer:
        li t0, 0x9000
        lw t1, 0(t0)
        addi t1, t1, 1
        sw t1, 0(t0)
        lw t2, 4(t0)
        li t0, 0x5000BFF8
        lw t1, 0(t0)
        add t1, t1, t2
        li t0, 0x50004000
        sw t1, 0(t0)
        j s_ret
s_ext:
        li t0, 0x900C
        lw t1, 0(t0)
        addi t1, t1, 1
        sw t1, 0(t0)
        j s_ret
s_syscall:
        li t1, 1
        beq a7, t1, s_sc_print
        li t1, 2
        beq a7, t1, s_sc_int
        li t1, 3
        beq a7, t1, s_sc_exit
        j s_unhandled
s_sc_print:
        jal ra, k_print_str
        j s_sysret
s_sc_int:
        jal ra, k_print_int
        j s_sysret
s_sc_exit:
        li t0, 0x9008
        sw a0, 0(t0)
        la a0, str_uexit
        jal ra, k_print_str
        li t0, 0x9008
        lw a0, 0(t0)
        jal ra, k_print_int
        li a0, 10
        jal ra, k_putc
        j k_shutdown
s_sysret:
        csrr t0, sepc
        addi t0, t0, 4
        csrw sepc, t0
        j s_ret
s_fault13:
        csrr t0, stval
        li t1, 0x60000000
        bne t0, t1, s_unhandled
        la a0, str_fault
        jal ra, k_print_str
        li a0, 13
        jal ra, k_print_int
        la a0, str_addr
        jal ra, k_print_str
        csrr a0, stval
        jal ra, k_print_hex
        li a0, 10
        jal ra, k_putc
        # Demand-map VA 0x60000000: root L1[384] -> L0 page
        # 0x14000, L0[0] -> PA 0x15000 U+R+W. Then sret with
        # sepc UNCHANGED, so the faulting load retries and
        # succeeds (the fresh page is zeroed RAM).
        li t0, 0x10000
        li t1, 0x5001
        sw t1, 1536(t0)
        li t0, 0x14000
        li t1, 0x5417
        sw t1, 0(t0)
        sfence.vma
        la a0, str_mapped
        jal ra, k_print_str
        j s_ret
s_unhandled:
        la a0, str_unhandled
        jal ra, k_print_str
        csrr a0, scause
        jal ra, k_print_int
        li a0, 10
        jal ra, k_putc
        j k_shutdown
s_ret:
        lw ra, 0(sp)
        lw t0, 4(sp)
        lw t1, 8(sp)
        lw t2, 12(sp)
        lw t3, 16(sp)
        lw t4, 20(sp)
        lw t5, 24(sp)
        lw t6, 28(sp)
        lw a0, 32(sp)
        lw a1, 36(sp)
        lw a2, 40(sp)
        lw a3, 44(sp)
        lw a4, 48(sp)
        lw a5, 52(sp)
        lw a6, 56(sp)
        lw a7, 60(sp)
        addi sp, sp, 64
        csrrw sp, sscratch, sp
        sret
# ---------------- print helpers (translated UART) ----------------
k_putc:
        li t0, 0x40000000
        sb a0, 0(t0)
        ret
k_print_str:
        addi sp, sp, -8
        sw ra, 0(sp)
        sw t1, 4(sp)
        li t0, 0x40000
        csrs sstatus, t0
        mv t1, a0
k_ps_loop:
        lb t0, 0(t1)
        beq t0, zero, k_ps_done
        mv a0, t0
        jal ra, k_putc
        addi t1, t1, 1
        j k_ps_loop
k_ps_done:
        li t0, 0x40000
        csrc sstatus, t0
        lw t1, 4(sp)
        lw ra, 0(sp)
        addi sp, sp, 8
        ret
k_print_int:
        addi sp, sp, -16
        sw ra, 12(sp)
        sw a0, 8(sp)
        bne a0, zero, k_pi_nonzero
        li a0, '0'
        jal ra, k_putc
        j k_pi_done
k_pi_nonzero:
        blt a0, zero, k_pi_neg
        j k_pi_count
k_pi_neg:
        li a0, '-'
        jal ra, k_putc
        lw a0, 8(sp)
        sub a0, zero, a0
        sw a0, 8(sp)
k_pi_count:
        lw t0, 8(sp)
        li t1, 0
        li t2, 10
k_pi_cloop:
        div t0, t0, t2
        addi t1, t1, 1
        bne t0, zero, k_pi_cloop
        sw t1, 0(sp)
        li t3, 1
        addi t4, t1, -1
k_pi_dloop:
        beq t4, zero, k_pi_out
        mul t3, t3, t2
        addi t4, t4, -1
        j k_pi_dloop
k_pi_out:
        sw t3, 4(sp)
k_pi_oloop:
        lw t0, 8(sp)
        lw t3, 4(sp)
        div t4, t0, t3
        rem t5, t0, t3
        sw t5, 8(sp)
        addi a0, t4, 48
        jal ra, k_putc
        lw t3, 4(sp)
        li t2, 10
        div t3, t3, t2
        sw t3, 4(sp)
        bne t3, zero, k_pi_oloop
k_pi_done:
        lw ra, 12(sp)
        addi sp, sp, 16
        ret
k_print_hex:
        addi sp, sp, -8
        sw ra, 0(sp)
        sw a0, 4(sp)
        la a0, str_0x
        jal ra, k_print_str
        li t1, 28
k_ph_loop:
        lw t0, 4(sp)
        srl t2, t0, t1
        andi t2, t2, 15
        li t3, 10
        blt t2, t3, k_ph_digit
        addi t2, t2, 87
        j k_ph_put
k_ph_digit:
        addi t2, t2, 48
k_ph_put:
        mv a0, t2
        jal ra, k_putc
        addi t1, t1, -4
        li t3, 0
        bge t1, t3, k_ph_loop
        lw ra, 0(sp)
        addi sp, sp, 8
        ret
str_kstart: STRING "S: kernel start\n"
str_ptok: STRING "S: pagetables ok\n"
str_trans: STRING "S: translation on\n"
str_ticks: STRING "S: ticks="
str_sdown: STRING "S: shutdown\n"
str_uexit: STRING "U: exit="
str_fault: STRING "FAULT: cause="
str_addr: STRING " addr="
str_mapped: STRING "FAULT: mapped page\n"
str_unhandled: STRING "S: unhandled cause="
str_0x: STRING "0x"
