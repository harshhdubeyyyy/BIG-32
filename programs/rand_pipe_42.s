li t0, 63
li t1, -72
li t2, -94
li a0, 89
li a1, -30
li a2, -38
li s0, -43
li s1, 256
lbu a1, 0(s1)
slt t1, a1, t1
lhu a1, 12(s1)
mulhu a1, a1, t2
lr.w s0, (s1)
addi s0, s0, 1
sc.w t1, s0, (s1)
lb t2, 8(s1)
sll a0, t2, t0
lr.w a1, (s1)
addi a1, a1, 1
sc.w s0, a1, (s1)
srl a0, s0, t0
sltu t2, a0, a2
csrrw t2, mscratch, a1
csrrs t1, mscratch, zero
rem t0, a2, t1
jal ra, sub_42_0
ori a0, a2, -23
sltiu t1, a2, -46
lb t1, 4(s1)
srai t2, t1, 14
lw s0, 4(s1)
amoadd.w s0, t2, (s1)
sltiu t0, t1, 16
sra a0, t0, a2
slt t1, a0, a2
sb a0, 12(s1)
addi t1, a1, -52
lr.w t1, (s1)
addi t1, t1, 1
sc.w t1, t1, (s1)
amoadd.w a0, t0, (s1)
ori a1, a0, -62
lh t0, 8(s1)
sra a0, t0, t1
slt a2, a0, t2
rem a1, t0, s0
lr.w a1, (s1)
addi a1, a1, 1
sc.w t1, a1, (s1)
mulhu s0, t1, a1
j end_main
sub_42_0:
sltu t0, t2, a0
sub t0, t2, s0
xor s0, t1, t0
sltu t1, t0, t0
ret
end_main:
mv a0, s0
ecall
