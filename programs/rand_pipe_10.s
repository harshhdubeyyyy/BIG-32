li t0, 46
li t1, -92
li t2, 9
li a0, 23
li a1, 47
li a2, -97
li s0, -48
li s1, 256
amoadd.w a2, t1, (s1)
or a0, a2, t0
bge t2, t0, skip_10_2
addi a2, t2, 1
skip_10_2: nop
lr.w a1, (s1)
addi a1, a1, 1
sc.w a0, a1, (s1)
srli s0, a2, 11
lbu a2, 4(s1)
jal ra, sub_10_0
lh t1, 8(s1)
remu t1, t1, t2
srli t0, a2, 10
lr.w a0, (s1)
addi a0, a0, 1
sc.w t0, a0, (s1)
mul t2, t0, a1
srl s0, t2, t1
sw t1, 0(s1)
srli s0, t1, 26
srai a2, t2, 11
lr.w t2, (s1)
addi t2, t2, 1
sc.w t2, t2, (s1)
mulhu a2, t2, t1
srl s0, a2, t2
sll a1, s0, t0
csrrw t1, mscratch, t0
csrrs t2, mscratch, zero
srli a1, t1, 15
remu t2, a1, a0
srl a0, t2, a0
slt a1, a0, t2
xori a2, t1, -39
jal ra, sub_10_0
slli t0, t0, 9
sra a0, t0, s0
slt s0, a0, s0
bge a2, t2, skip_10_30
addi t2, a2, 1
skip_10_30: nop
slli a2, a1, 15
sltiu t0, a2, 58
or t0, t0, a0
div t0, t0, a1
jal ra, sub_10_1
or a1, a0, s0
jal ra, sub_10_0
srli t0, a2, 27
srli a2, a1, 23
or s0, a2, t0
srai a0, s0, 12
add a0, a0, t0
andi t2, a0, 8
srai t2, a1, 16
j end_main
sub_10_0:
mul a0, t2, t2
xor a2, a0, a0
sra s0, a1, a0
ret
sub_10_1:
slt a2, a2, t2
mulh s0, a0, s0
ret
end_main:
mv a0, s0
ecall
