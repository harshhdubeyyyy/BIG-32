li t0, -52
li t1, -76
li t2, -24
li a0, 70
li a1, 86
li a2, -35
li s0, 90
li s1, 256
lb a2, 12(s1)
andi a1, a2, -20
sltiu t2, a2, -17
sll s0, t2, t2
and s0, s0, t1
srai t1, a1, 16
remu s0, t1, a2
beq t0, a2, skip_78_7
addi a2, t0, 1
skip_78_7: nop
srl a2, a2, t1
amoadd.w a0, t1, (s1)
lhu a2, 8(s1)
ori a1, a2, -33
lw a1, 4(s1)
addi t0, a1, 49
divu t1, t0, t2
srli a0, a1, 8
srl s0, a0, s0
sw t0, 0(s1)
ori t1, s0, 12
beq a2, t1, skip_78_19
addi s0, a2, 1
skip_78_19: nop
slli t0, a1, 25
jal ra, sub_78_1
amoadd.w t1, t0, (s1)
slti a0, s0, 11
blt t0, a0, skip_78_24
addi s0, t0, 1
skip_78_24: nop
andi a0, t1, 40
slti a1, a0, -31
lr.w a2, (s1)
addi a2, a2, 1
sc.w a0, a2, (s1)
sb t2, 12(s1)
sh t1, 4(s1)
rem s0, s0, t2
j end_main
sub_78_0:
add t0, a2, a1
slt a0, a1, t2
mul a1, a1, a0
ret
sub_78_1:
sltu a1, a1, a0
mulh a1, t1, t2
xor t0, a0, s0
sll s0, s0, s0
ret
end_main:
mv a0, s0
ecall
