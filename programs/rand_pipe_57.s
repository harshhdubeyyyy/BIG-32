li t0, -90
li t1, -6
li t2, 50
li a0, 54
li a1, -96
li a2, -43
li s0, 31
li s1, 256
xori a0, a2, -59
lr.w t1, (s1)
addi t1, t1, 1
sc.w a1, t1, (s1)
sltiu a0, t0, 60
sw a1, 4(s1)
sltu a1, a0, s0
bge s0, t1, skip_57_5
addi a1, s0, 1
skip_57_5: nop
andi a1, a1, 7
addi t1, a0, 53
srli a0, t0, 28
sb a0, 0(s1)
ori t2, t2, 3
add a2, t2, t1
lb a0, 0(s1)
and a0, a0, t1
sw t0, 8(s1)
slti a2, t1, -1
lhu s0, 4(s1)
mulh t1, s0, s0
jal ra, sub_57_1
and a1, a0, s0
lbu a1, 4(s1)
amoadd.w t1, a2, (s1)
add t0, t1, t1
csrrw s0, mscratch, s0
csrrs a0, mscratch, zero
lr.w t0, (s1)
addi t0, t0, 1
sc.w a1, t0, (s1)
lr.w a2, (s1)
addi a2, a2, 1
sc.w a2, a2, (s1)
lbu t2, 12(s1)
xori a0, t2, 23
sltiu a0, t1, -64
jal ra, sub_57_0
slli a2, s0, 5
mul a1, a2, t0
divu t0, a2, t0
divu a2, t1, t0
mulhu s0, a2, s0
amoadd.w a2, t1, (s1)
xori t0, a1, -5
sltiu a2, a1, 58
lr.w t2, (s1)
addi t2, t2, 1
sc.w a0, t2, (s1)
jal ra, sub_57_0
mulhu a1, t1, a1
lr.w s0, (s1)
addi s0, s0, 1
sc.w t2, s0, (s1)
sh a0, 12(s1)
slti t1, t0, -16
add a0, t1, t1
j end_main
sub_57_0:
xor t2, t1, t1
sll t2, a1, a2
ret
sub_57_1:
or t2, a1, t1
sll s0, a0, t1
mulhu a2, a2, t1
mul t1, t1, s0
ret
end_main:
mv a0, s0
ecall
