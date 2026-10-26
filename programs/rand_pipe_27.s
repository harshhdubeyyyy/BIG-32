li t0, 66
li t1, 22
li t2, 79
li a0, -30
li a1, -27
li a2, -50
li s0, -82
li s1, 256
amoadd.w t2, t2, (s1)
lr.w a0, (s1)
addi a0, a0, 1
sc.w t1, a0, (s1)
csrrw a0, mscratch, s0
csrrs t0, mscratch, zero
div a2, a1, a2
lw a0, 12(s1)
jal ra, sub_27_0
mul a1, t2, a1
sub s0, a1, t1
jal ra, sub_27_0
remu a1, t0, t1
divu t2, a1, t0
jal ra, sub_27_0
addi a1, a1, 14
jal ra, sub_27_0
and t1, s0, t2
sw a1, 4(s1)
sub a2, t1, a1
ori s0, t0, -35
sltiu s0, a1, -43
addi a0, t2, -59
csrrw t1, mscratch, s0
csrrs a0, mscratch, zero
sb t0, 0(s1)
slti t1, t2, -40
sra a0, t1, a2
div t1, s0, t2
lh t1, 12(s1)
amoadd.w t0, t2, (s1)
jal ra, sub_27_0
xori t1, a0, -38
add t2, t1, t2
lbu t1, 4(s1)
lr.w a0, (s1)
addi a0, a0, 1
sc.w s0, a0, (s1)
andi t1, a1, 21
jal ra, sub_27_0
slli a1, a1, 15
slli t2, t0, 25
csrrw t2, mscratch, t1
csrrs t1, mscratch, zero
divu a2, a2, t0
j end_main
sub_27_0:
sltu t0, a1, a1
sra s0, a1, t0
xor t1, a1, t1
ret
end_main:
mv a0, s0
ecall
