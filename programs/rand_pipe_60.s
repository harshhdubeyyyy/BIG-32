li t0, -22
li t1, -28
li t2, 47
li a0, -61
li a1, -33
li a2, -42
li s0, 23
li s1, 256
jal ra, sub_60_0
lw t1, 4(s1)
lb t0, 4(s1)
sltiu a2, t0, -26
sw a1, 0(s1)
jal ra, sub_60_0
addi t1, a1, -8
mulh t2, t1, t1
amoadd.w t1, a2, (s1)
jal ra, sub_60_1
sltiu t0, s0, -40
sub a1, t0, t0
slt a0, a1, t2
sb a0, 4(s1)
slti t2, a0, 34
sub t2, t2, t1
lr.w t1, (s1)
addi t1, t1, 1
sc.w a1, t1, (s1)
sra a0, a1, a1
jal ra, sub_60_0
csrrw t1, mscratch, t2
csrrs a2, mscratch, zero
srai a0, t1, 14
sb t2, 4(s1)
mulhu a2, a0, a0
ori s0, t1, -5
divu a1, a2, a2
beq t2, s0, skip_60_25
addi t2, t2, 1
skip_60_25: nop
slt a0, t2, t1
addi a2, t1, -35
lhu t1, 12(s1)
lb t0, 4(s1)
srai s0, t0, 27
sw t2, 8(s1)
sra t2, s0, s0
srai s0, a0, 3
sltiu s0, a0, 13
srai t0, t0, 15
divu t1, a0, t0
lr.w s0, (s1)
addi s0, s0, 1
sc.w t2, s0, (s1)
mul s0, t2, a2
amoadd.w t1, s0, (s1)
j end_main
sub_60_0:
mulh t2, a2, t0
sltu a1, t1, a1
sltu a2, a2, t0
ret
sub_60_1:
mul a2, a0, s0
mulhu a0, s0, t1
mulhu t0, t2, a1
sub s0, a1, t0
ret
end_main:
mv a0, s0
ecall
