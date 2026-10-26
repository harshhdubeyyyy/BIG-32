li t0, 1
li t1, -52
li t2, -15
li a0, -53
li a1, 60
li a2, -97
li s0, 34
li s1, 256
lb t1, 4(s1)
srli t2, t1, 8
ori t0, a0, -49
or t1, t0, t1
slt t0, t1, a2
bge a1, t0, skip_88_5
addi s0, a1, 1
skip_88_5: nop
div a1, a0, a0
sw t1, 12(s1)
csrrw a2, mscratch, s0
csrrs a2, mscratch, zero
slt t1, a2, a1
or t2, t1, a2
jal ra, sub_88_0
remu a1, t2, a1
slt t2, a1, a0
remu s0, t2, a0
or t2, s0, s0
beq t2, t0, skip_88_16
addi s0, t2, 1
skip_88_16: nop
sltiu t1, a1, 8
and t0, t1, t2
mul a1, t0, s0
and t0, a1, a0
lb t0, 12(s1)
ori a1, t0, -41
csrrw t2, mscratch, a1
csrrs a1, mscratch, zero
beq t2, a2, skip_88_24
addi t1, t2, 1
skip_88_24: nop
mulh t2, t1, t1
xori a1, s0, 38
sw a0, 0(s1)
ori t2, t2, 30
srai a2, a2, 21
lh t1, 4(s1)
lbu a0, 12(s1)
and s0, a0, t2
mul t0, s0, a2
srli a2, t2, 28
bne a2, t1, skip_88_35
addi a0, a2, 1
skip_88_35: nop
divu t1, a2, t2
div a2, a2, a1
sll t1, a2, t1
sh a0, 8(s1)
j end_main
sub_88_0:
srl s0, a0, s0
add a0, t2, a1
ret
end_main:
mv a0, s0
ecall
