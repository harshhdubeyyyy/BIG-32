li t0, -8
li t1, 20
li t2, 23
li a0, -28
li a1, 6
li a2, -42
li s0, 14
li s1, 256
lr.w a2, (s1)
addi a2, a2, 1
sc.w t1, a2, (s1)
lh t0, 4(s1)
beq t0, t2, skip_16_2
addi a1, t0, 1
skip_16_2: nop
amoadd.w a1, t0, (s1)
csrrw s0, mscratch, a1
csrrs a2, mscratch, zero
lh a0, 4(s1)
amoadd.w t2, t2, (s1)
srli t0, t2, 11
blt a1, t0, skip_16_8
addi t2, a1, 1
skip_16_8: nop
jal ra, sub_16_0
sll t1, t2, t2
srli t0, t1, 0
srli s0, a0, 7
srai a1, t0, 1
jal ra, sub_16_0
srl t0, a2, a2
lw a0, 4(s1)
slti a2, a0, -33
sub a0, a2, t0
remu t0, s0, s0
or a2, t0, t2
or t0, a2, a1
blt a2, t1, skip_16_22
addi t0, a2, 1
skip_16_22: nop
sltiu t0, a0, 55
srai t0, t0, 12
slli t2, a1, 13
sub a2, t2, t2
slli t1, s0, 8
csrrw a0, mscratch, a0
csrrs a1, mscratch, zero
sra t1, a1, a2
amoadd.w s0, t1, (s1)
lh s0, 8(s1)
jal ra, sub_16_0
remu t1, a1, a2
sra a0, t1, t1
sw a2, 8(s1)
mulh t0, a0, a0
divu a1, t2, a1
srl t2, a1, t2
mulh t1, t2, t1
srl t0, t1, t2
lw t1, 12(s1)
lhu t1, 4(s1)
j end_main
sub_16_0:
mulhu a1, s0, a2
slt s0, a2, s0
ret
end_main:
mv a0, s0
ecall
