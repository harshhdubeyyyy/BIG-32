li t0, 63
li t1, 7
li t2, 9
li a0, 93
li a1, 85
li a2, -74
li s0, -84
li s1, 256
slti a1, a2, 24
sltiu a2, t2, 14
slli s0, a1, 5
sw a1, 0(s1)
slti a2, a1, -58
mulh t0, a2, t0
mulhu a0, t0, t0
xori a2, t1, 43
sh t1, 8(s1)
lw t1, 4(s1)
sh t1, 0(s1)
mulhu s0, t1, t1
slti t0, t0, 24
csrrw a1, mscratch, t0
csrrs t1, mscratch, zero
addi a2, a0, -23
lw t0, 4(s1)
slti a1, t0, 3
mul t2, a1, t2
divu s0, t0, a0
addi t1, a0, 12
div a0, t0, t0
sh a0, 0(s1)
remu t2, a0, a2
srai t1, t1, 6
lb t2, 0(s1)
lb s0, 8(s1)
sub t1, s0, a1
slti a0, a0, 38
slli t1, a2, 22
sltu t1, t1, a1
csrrw t2, mscratch, s0
csrrs s0, mscratch, zero
slt t0, s0, a2
sltiu t2, t2, 47
mulhu a0, t2, a2
lh t1, 4(s1)
lr.w a0, (s1)
addi a0, a0, 1
sc.w a2, a0, (s1)
jal ra, sub_38_1
remu t0, s0, t2
csrrw t2, mscratch, t2
csrrs a1, mscratch, zero
add t2, a1, t0
mulh t2, t2, s0
amoadd.w t1, t0, (s1)
div t2, t0, a2
amoadd.w a1, a0, (s1)
j end_main
sub_38_0:
mul a2, t1, a0
and t0, t1, t1
mulhu t2, a2, s0
sltu a0, t1, s0
ret
sub_38_1:
xor t1, s0, s0
add a0, a2, a1
ret
end_main:
mv a0, s0
ecall
