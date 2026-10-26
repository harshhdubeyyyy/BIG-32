li t0, 13
li t1, 13
li t2, -25
li a0, -36
li a1, 23
li a2, 68
li s0, -78
li s1, 256
mul t1, t2, t0
andi a2, a1, -32
addi t2, a1, -56
bne a2, t1, skip_63_3
addi a1, a2, 1
skip_63_3: nop
rem a1, a0, a0
sw t0, 8(s1)
lhu s0, 4(s1)
lbu s0, 0(s1)
ori t2, s0, 44
slt a2, t2, a2
srl a1, a2, a1
amoadd.w a0, a2, (s1)
lr.w s0, (s1)
addi s0, s0, 1
sc.w s0, s0, (s1)
sltiu a0, s0, -25
andi t0, s0, 28
or t2, t0, a0
mulhu a0, t2, t1
slti t2, s0, 0
or s0, t2, t0
slti a1, a2, 37
srai t0, a2, 30
xori t1, t1, 2
slt s0, t1, a1
and a2, s0, t2
ori t0, a1, 40
sll s0, t0, s0
xori t2, a0, 37
sltu a0, t2, a0
xori t1, s0, -45
remu a2, t0, t1
slt t2, a2, t2
slti a2, t0, -40
j end_main
sub_63_0:
and a1, t2, t2
sll s0, t1, t1
mulh t0, a2, a2
ret
sub_63_1:
sra t1, t2, s0
mul a0, t1, a1
ret
end_main:
mv a0, s0
ecall
