li t0, 40
li t1, -20
li t2, -67
li a0, 42
li a1, 82
li s0, 36
li s1, 256
sw s0, 0(s1)
slli t1, t1, 31
slti t1, a1, -25
addi t0, t0, -31
sltiu t1, t1, 10
lw s0, 0(s1)
sw s0, 0(s1)
and a1, t2, s0
srl a0, t1, t1
sw t0, 0(s1)
sltu t2, a1, t2
andi t0, t0, 20
addi s0, t2, -62
sw t2, 0(s1)
srl a1, s0, s0
ori a1, t2, -15
slti s0, t1, -22
sltu t1, t2, s0
sw a1, 0(s1)
sltiu a0, a1, -61
lw a1, 0(s1)
addi t0, t0, 21
sra t0, s0, a1
slti a0, t0, -42
slti t1, t0, -14
sw a0, 0(s1)
bne t0, t2, skip_48_33
addi a0, t0, 1
skip_48_33: nop
sltiu s0, t2, 44
rem t1, a0, t2
mv a0, s0
ecall
