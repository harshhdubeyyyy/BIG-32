li t0, -43
li t1, -79
li t2, 66
li a0, 17
li a1, -95
li a2, -66
li s0, -24
li s1, 256
sra s0, a0, a0
amoadd.w a1, s0, (s1)
and a1, a1, a2
jal ra, sub_59_0
lw s0, 0(s1)
sltu t0, s0, a1
jal ra, sub_59_0
lr.w a1, (s1)
addi a1, a1, 1
sc.w a2, a1, (s1)
ori s0, t0, -7
ori a2, a0, -31
csrrw t0, mscratch, a2
csrrs a1, mscratch, zero
sltiu a0, a1, 1
slti a1, t1, -10
sltu a0, a1, a1
srli a2, a2, 3
ori t0, t2, 37
lw t0, 4(s1)
sh t0, 12(s1)
sll a2, t0, a1
ori a2, t0, -48
xori a2, a2, -23
jal ra, sub_59_0
lr.w s0, (s1)
addi s0, s0, 1
sc.w t2, s0, (s1)
addi t2, t0, 24
mulh a1, t2, t2
mulh t2, a1, t0
sb s0, 4(s1)
and t0, t2, t2
and s0, t0, t1
lr.w s0, (s1)
addi s0, s0, 1
sc.w a2, s0, (s1)
slt a2, a2, a1
jal ra, sub_59_0
mulh a0, a2, a2
mul t1, a0, a2
sw a0, 4(s1)
mulh a2, t1, t1
slt a0, a2, s0
slli t1, s0, 14
csrrw t0, mscratch, a2
csrrs t2, mscratch, zero
lr.w a2, (s1)
addi a2, a2, 1
sc.w t2, a2, (s1)
mulhu t2, t2, t0
lbu a0, 0(s1)
bne a0, a0, skip_59_42
addi a1, a0, 1
skip_59_42: nop
andi a2, a0, -59
mulhu a0, a2, t2
sub a1, a0, a0
bne t0, a2, skip_59_46
addi s0, t0, 1
skip_59_46: nop
remu t2, t1, a1
lw a1, 8(s1)
j end_main
sub_59_0:
or s0, a2, s0
sra t0, a1, a0
ret
end_main:
mv a0, s0
ecall
