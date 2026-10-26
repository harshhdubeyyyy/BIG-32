li t0, 74
li t1, 55
li t2, -77
li a0, 58
li a1, 70
li a2, 91
li s0, 62
li s1, 256
jal ra, sub_37_0
jal ra, sub_37_0
bne a0, a0, skip_37_2
addi a2, a0, 1
skip_37_2: nop
bge t0, t0, skip_37_3
addi s0, t0, 1
skip_37_3: nop
mulh t2, s0, a2
srai a1, a1, 2
amoadd.w a1, a1, (s1)
slti t0, t0, 28
sll a1, t0, t0
addi t1, s0, -61
csrrw t1, mscratch, a2
csrrs a2, mscratch, zero
ori t1, a1, -54
andi a2, t1, -10
sra a2, a2, a0
mul a2, a2, t2
sll a0, a2, t1
slti t0, t1, -24
lhu a2, 8(s1)
srai a1, a2, 18
srl t0, a1, t1
sh t0, 8(s1)
mulhu s0, t0, t1
or a0, s0, t0
or t2, a0, t1
rem a1, a2, a0
divu t2, a1, t0
div s0, t2, a2
beq a1, s0, skip_37_27
addi a1, a1, 1
skip_37_27: nop
mulhu a0, a1, t2
amoadd.w t2, s0, (s1)
lh t2, 12(s1)
jal ra, sub_37_0
lh a1, 8(s1)
mulh t1, a1, t0
div a0, a1, a1
sh a2, 4(s1)
sub t1, a0, s0
sub s0, t1, s0
sub t1, s0, t0
ori t0, a2, 58
amoadd.w t0, a1, (s1)
or t2, t0, a0
lbu a1, 8(s1)
beq a1, a1, skip_37_43
addi s0, a1, 1
skip_37_43: nop
slli a1, s0, 4
sll a0, a1, a0
and t1, a0, s0
lbu a2, 8(s1)
mul t1, a2, t1
beq a1, a0, skip_37_49
addi s0, a1, 1
skip_37_49: nop
j end_main
sub_37_0:
slt t0, a2, t1
slt t0, a2, t1
ret
end_main:
mv a0, s0
ecall
