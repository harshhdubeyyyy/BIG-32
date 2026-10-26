li t0, -40
li t1, -23
li t2, -74
li a0, 84
li a1, 1
li s0, 22
li s1, 256
remu t0, a0, a1
slt t0, t1, a1
or t1, t0, t2
bne s0, t2, skip_4_10
addi t0, s0, 1
skip_4_10: nop
sw t2, 0(s1)
rem s0, t2, t0
andi s0, a0, -19
rem t2, t0, a1
remu t2, a1, s0
srl a1, t1, a0
andi a0, a0, 14
sra t0, t0, t0
sltiu t2, a1, 56
slli t1, s0, 26
lw s0, 0(s1)
sltu t2, a0, s0
sub a1, t1, t2
sw t2, 0(s1)
srli a1, t1, 11
div t0, t0, t2
sll t2, s0, s0
divu t2, t2, t1
ori a1, s0, -15
lw t2, 0(s1)
mv a0, s0
ecall
