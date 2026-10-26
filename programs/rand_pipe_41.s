li t0, -3
li t1, -15
li t2, -41
li a0, -58
li a1, -2
li a2, 47
li s0, 76
li s1, 256
sltu s0, a2, s0
add t1, s0, s0
srli t1, t1, 10
add a2, t1, a1
xor a1, a2, a0
lr.w t1, (s1)
addi t1, t1, 1
sc.w a2, t1, (s1)
sltiu a0, t1, -60
add t1, a0, t1
sltu t1, t1, t0
sw s0, 8(s1)
xori t0, a2, -59
lb a0, 0(s1)
mulh t0, a0, a0
slti a1, a2, -57
csrrw a2, mscratch, a0
csrrs t2, mscratch, zero
add s0, t2, a2
div a2, s0, s0
jal ra, sub_41_0
lw a0, 4(s1)
sra t2, a0, a2
lw a0, 8(s1)
sh a0, 12(s1)
csrrw t2, mscratch, s0
csrrs a1, mscratch, zero
sltiu t2, s0, -44
or t1, t2, t0
or a2, t1, t0
sh a0, 0(s1)
sra a2, a2, t0
lbu a2, 12(s1)
jal ra, sub_41_1
mul a1, a2, t1
srl a1, a1, t1
rem s0, t0, t0
and a0, s0, t2
sub a0, a0, t1
lr.w t2, (s1)
addi t2, t2, 1
sc.w a1, t2, (s1)
sltiu a0, s0, -3
or a0, a0, a0
sw t0, 12(s1)
slli a1, s0, 1
remu a2, t1, a0
xori t2, a1, -60
srl s0, t2, a1
srl a2, s0, a1
sltu s0, a2, t2
or s0, s0, a2
ori t1, t0, -17
j end_main
sub_41_0:
sltu t0, a1, a2
or t0, t2, t1
sra t2, t0, s0
ret
sub_41_1:
sra s0, t0, a2
sub t2, t2, a0
sub s0, a1, s0
mul t2, a0, s0
ret
end_main:
mv a0, s0
ecall
