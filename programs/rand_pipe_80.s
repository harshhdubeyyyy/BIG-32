li t0, -31
li t1, 0
li t2, 38
li a0, 81
li a1, 7
li a2, -6
li s0, -7
li s1, 256
or s0, s0, a0
bne a0, t1, skip_80_1
addi t0, a0, 1
skip_80_1: nop
bge t0, t1, skip_80_2
addi a1, t0, 1
skip_80_2: nop
lh t1, 4(s1)
lh t1, 0(s1)
sltiu a2, t1, -63
sltu t2, a2, t2
sw a2, 4(s1)
lw a1, 12(s1)
mulhu t2, a1, a0
lhu a2, 0(s1)
addi t0, a2, -62
sra a1, t0, t2
lbu a1, 4(s1)
lr.w a0, (s1)
addi a0, a0, 1
sc.w t1, a0, (s1)
and a0, t1, a2
lr.w s0, (s1)
addi s0, s0, 1
sc.w t0, s0, (s1)
lr.w a0, (s1)
addi a0, a0, 1
sc.w t2, a0, (s1)
sb s0, 12(s1)
mulhu t1, t2, a1
ori s0, a0, -34
sh a0, 0(s1)
sll a2, s0, t0
sltu t2, a2, t2
andi t2, a1, -34
and t1, t2, s0
lbu s0, 8(s1)
lr.w s0, (s1)
addi s0, s0, 1
sc.w t0, s0, (s1)
amoadd.w a2, a0, (s1)
or s0, a2, t0
lw s0, 4(s1)
sll a2, s0, s0
srl t1, a2, t2
lr.w a2, (s1)
addi a2, a2, 1
sc.w a1, a2, (s1)
sltu a0, a1, a0
lw t0, 8(s1)
jal ra, sub_80_0
lh t2, 12(s1)
remu a1, t2, t1
jal ra, sub_80_1
or a1, s0, t2
j end_main
sub_80_0:
sra a1, a2, t2
slt t1, t0, a0
sll t0, a2, s0
ret
sub_80_1:
and t1, t2, t2
mulhu t2, t0, a0
and a0, t1, t2
ret
end_main:
mv a0, s0
ecall
