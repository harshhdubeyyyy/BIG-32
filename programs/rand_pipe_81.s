li t0, 29
li t1, 16
li t2, -14
li a0, 42
li a1, 36
li a2, -2
li s0, 22
li s1, 256
sltu a2, s0, s0
sll t2, a2, a2
sub a2, t2, a1
slt s0, a2, a1
jal ra, sub_81_0
sra s0, t1, a2
mulh a0, s0, a1
rem s0, a0, t2
ori s0, t2, -39
xor a0, s0, t2
lr.w t1, (s1)
addi t1, t1, 1
sc.w t1, t1, (s1)
slli t1, t1, 19
slti t0, t0, -20
or s0, t0, a0
mulh t2, s0, t0
sub a0, t2, t2
andi a2, t0, -40
mulhu a2, a2, s0
rem a2, t1, t2
csrrw a1, mscratch, s0
csrrs t0, mscratch, zero
srli a1, a0, 12
srl s0, a1, t2
lb a1, 0(s1)
sw a1, 4(s1)
amoadd.w t2, a2, (s1)
remu a1, t1, t1
srl t0, a1, a1
andi a2, s0, -5
addi t2, s0, 14
addi s0, t2, 46
or a2, s0, t2
jal ra, sub_81_0
mulh t1, a2, t0
lbu a0, 0(s1)
sltiu t1, a0, -53
j end_main
sub_81_0:
and t1, s0, a0
srl a0, a0, s0
ret
end_main:
mv a0, s0
ecall
