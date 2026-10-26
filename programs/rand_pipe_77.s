li t0, -36
li t1, -17
li t2, -50
li a0, -39
li a1, -51
li a2, -71
li s0, -26
li s1, 256
jal ra, sub_77_0
lr.w t0, (s1)
addi t0, t0, 1
sc.w a0, t0, (s1)
srl s0, a0, a1
slt t2, s0, t0
divu a1, a0, t1
mulh t0, a1, t1
sb a2, 0(s1)
or s0, t0, a2
remu s0, t0, t0
amoadd.w s0, a1, (s1)
jal ra, sub_77_0
xori a1, t0, -1
and a0, a1, a2
div a0, t0, t0
sh t2, 0(s1)
sra a1, a0, a2
mul a0, a1, a2
add t2, a0, t0
lr.w t2, (s1)
addi t2, t2, 1
sc.w s0, t2, (s1)
xori t0, t0, -27
div s0, t0, a2
srl a2, s0, t0
jal ra, sub_77_0
and s0, s0, t0
or t0, s0, s0
lhu s0, 12(s1)
sw s0, 12(s1)
lh t2, 12(s1)
csrrw t0, mscratch, t2
csrrs a1, mscratch, zero
sw a2, 0(s1)
mul t0, a1, t1
mul a0, t0, t0
sltiu a0, a0, 38
xor s0, a0, a0
slti s0, t0, 18
ori t1, s0, 58
jal ra, sub_77_1
sh t2, 8(s1)
bne a2, t0, skip_77_38
addi t2, a2, 1
skip_77_38: nop
or s0, t2, t0
beq a1, a1, skip_77_40
addi a1, a1, 1
skip_77_40: nop
sw a1, 4(s1)
add t1, a1, t2
lbu a2, 0(s1)
csrrw t2, mscratch, a2
csrrs t0, mscratch, zero
addi a2, a1, -52
srli s0, t1, 4
j end_main
sub_77_0:
sub t0, t0, a0
and s0, t0, s0
mulhu a2, t2, s0
ret
sub_77_1:
mul t2, s0, t1
mul a1, t0, t0
slt t0, a2, a0
mulh a1, t0, t1
ret
end_main:
mv a0, s0
ecall
