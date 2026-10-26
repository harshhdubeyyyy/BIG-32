# S-mode SBI test (Phase 5). Entry at RAM offset 0x1000, with
# a0=hartid, a1=DTB address (from the SBI firmware). s0 = fails,
# s1 = S timer ticks. Ends via SBI system_reset (firmware halts).
start:
    li sp, 0x8000F000
    li s0, 0
    li s1, 0
    la t1, s_handler
    csrw stvec, t1
    li t1, 0x20
    csrw sie, t1        # STIE
    li t1, 0x2
    csrs sstatus, t1    # SIE
    # DTB magic: bytes D0 0D FE ED at a1.
    lbu t0, 0(a1)
    li t1, 0xD0
    bne t0, t1, fail
    lbu t0, 1(a1)
    li t1, 0x0D
    bne t0, t1, fail
    lbu t0, 2(a1)
    li t1, 0xFE
    bne t0, t1, fail
    lbu t0, 3(a1)
    li t1, 0xED
    bne t0, t1, fail
    # DTB totalsize (big-endian u32 at +4) must be sane.
    lbu t0, 4(a1)
    slli t0, t0, 24
    lbu t1, 5(a1)
    slli t1, t1, 16
    or t0, t0, t1
    lbu t1, 6(a1)
    slli t1, t1, 8
    or t0, t0, t1
    lbu t1, 7(a1)
    or t0, t0, t1
    li t1, 100
    blt t0, t1, fail
    li t1, 65536
    bge t0, t1, fail
    # SBI base: get_spec_version -> 2.0.
    li a7, 0x10
    li a6, 0
    ecall
    bne a0, x0, fail
    li t1, 0x02000000
    bne a1, t1, fail
    # Probe TIME -> 1, probe bogus -> 0.
    li a7, 0x10
    li a6, 3
    li a0, 0x54494D45
    ecall
    bne a0, x0, fail
    li t1, 1
    bne a1, t1, fail
    li a7, 0x10
    li a6, 3
    li a0, 0x12345678
    ecall
    bne a0, x0, fail
    bne a1, x0, fail
    # Legacy putchar 'S'.
    li a7, 1
    li a0, 0x53
    ecall
    bne a0, x0, fail
    # Timer: set mtimecmp = mtime + 2000 via SBI TIME, wait for
    # one S timer tick, then stop the timer.
    li t0, 0x0200BFF8
    lw t1, 0(t0)
    lw t2, 4(t0)
    addi t1, t1, 2000
    # (mtime is tiny at this point, so +2000 cannot wrap the
    # low word into the high word; the high word is passed
    # through unchanged.)
    li a7, 0x54494D45
    li a6, 0
    mv a0, t1
    mv a1, t2
    ecall
    bne a0, x0, fail
    li t2, 8000
wait_tick:
    addi t2, t2, -1
    bne t2, x0, wait_tick
    li t1, 1
    bne s1, t1, fail
    # Stop the timer: SIE off first, then far-future set_timer.
    li t1, 0x2
    csrc sstatus, t1
    li a7, 0x54494D45
    li a6, 0
    li a0, -1
    li a1, -1
    ecall
    # Shutdown via SRST. If it returns, that is a failure and
    # the program loops (the checker reports halted=0).
    li a7, 0x53525354
    li a6, 0
    li a0, 0
    li a1, 0
    ecall
    addi s0, s0, 1
spin:
    j spin
fail:
    addi s0, s0, 1
    # Fall through to the shutdown path again: re-run the SRST
    # call (it halts on success; if it returns, spin).
    li a7, 0x53525354
    li a6, 0
    li a0, 0
    li a1, 0
    ecall
    j spin

s_handler:
    addi sp, sp, -8
    sw t0, 0(sp)
    # The S timer interrupt is level (mtime >= mtimecmp stays
    # true), so mask it on the first tick or it retakes forever.
    li t0, 0x20
    csrc sie, t0
    addi s1, s1, 1
    lw t0, 0(sp)
    addi sp, sp, 8
    sret
