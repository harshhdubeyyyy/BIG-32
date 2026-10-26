li t0, -70
li t1, -25
li t2, 79
li a0, 17
li a1, 15
li a2, -66
li s0, -18
li s1, 256
amoadd.w a2, t1, (s1)
divu a0, s0, a0
ori t0, a1, 32
amoadd.w a0, t0, (s1)
and a0, a0, t2
sub a0, a0, s0
sw s0, 4(s1)
addi a1, t1, -49
sb s0, 8(s1)
or a1, a1, t0
lr.w a1, (s1)
addi a1, a1, 1
sc.w a1, a1, (s1)
lw a2, 4(s1)
sh a2, 4(s1)
rem s0, t2, s0
amoadd.w a2, a1, (s1)
add a0, a2, t0
lw t1, 8(s1)
jal ra, sub_70_0
div t0, a0, t2
slt t2, t0, t1
lh t2, 0(s1)
sw t2, 0(s1)
mulhu t1, t2, a0
mul t0, t1, t0
lh a2, 8(s1)
divu t0, a2, s0
lhu t1, 12(s1)
sra t1, t1, a0
lh t2, 4(s1)
rem a1, t2, a1
slli a2, s0, 28
slti t1, t2, -55
sltiu s0, t1, -29
blt t1, a2, skip_70_33
addi t2, t1, 1
skip_70_33: nop
j end_main
sub_70_0:
sub s0, t0, s0
xor s0, a1, s0
mulh t1, s0, a0
ret
end_main:
mv a0, s0
ecall
