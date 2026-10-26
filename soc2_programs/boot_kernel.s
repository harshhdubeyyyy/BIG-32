# Boot kernel (S-mode, bare): loaded by the bootloader from
# virtio sectors 0-1 into RAM at 0x80010000, entered with
# a0=hartid, a1=DTB address. Proves the load worked by
# checking the DTB magic, printing 'B' + 'K' via SBI putchar,
# checking the SBI spec version, and shutting down via SRST.
# s0 = fail count at halt (preserved through the firmware's
# SRST handler, which does not touch s0). Any trap lands in
# trap_fail (also SRST + spin). If SRST returns, spin (the
# checker then reports halted=0, an honest failure signal).
start:
    li sp, 0x8000F000
    li s0, 0
    la t0, trap_fail
    csrw stvec, t0
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
    li a7, 1
    li a0, 0x42
    ecall
    bne a0, x0, fail
    li a7, 1
    li a0, 0x4B
    ecall
    bne a0, x0, fail
    li a7, 0x10
    li a6, 0
    ecall
    bne a0, x0, fail
    li t1, 0x02000000
    bne a1, t1, fail
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
    li a7, 0x53525354
    li a6, 0
    li a0, 0
    li a1, 0
    ecall
    j spin
trap_fail:
    addi s0, s0, 1
    li a7, 0x53525354
    li a6, 0
    li a0, 0
    li a1, 0
    ecall
    j spin
