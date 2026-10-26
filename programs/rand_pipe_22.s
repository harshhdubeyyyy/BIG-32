li t0, -65
li t1, -38
li t2, -94
li a0, 56
li a1, 14
li a2, -53
li s0, 79
li s1, 256
csrrw s0, mscratch, t0
csrrs t1, mscratch, zero
and t0, t1, a1
beq a2, a0, skip_22_2
addi a2, a2, 1
skip_22_2: nop
sh t2, 12(s1)
slt s0, a2, a1
blt a1, t0, skip_22_5
addi s0, a1, 1
skip_22_5: nop
lh t2, 4(s1)
mulh t2, t2, a2
add t0, t2, a1
slti t2, a1, 40
ori t1, t2, 37
lhu t2, 12(s1)
div a1, t2, a0
srl a0, a1, t0
amoadd.w t0, t1, (s1)
sh t0, 4(s1)
and a1, t0, t2
xori t2, a2, -55
mul t1, t2, s0
div a2, a2, t0
sltu t0, a2, t1
srai s0, t0, 8
lbu a2, 12(s1)
rem a2, a2, a2
blt s0, s0, skip_22_24
addi t0, s0, 1
skip_22_24: nop
blt t1, a1, skip_22_25
addi t0, t1, 1
skip_22_25: nop
lhu t2, 12(s1)
lw t1, 4(s1)
slti t0, t1, 1
sh t0, 0(s1)
lh a1, 0(s1)
divu a1, a1, s0
sltu a0, a1, s0
mul t1, a0, a0
xori s0, a2, 54
sub t1, s0, t2
blt t1, t1, skip_22_36
addi a1, t1, 1
skip_22_36: nop
xor a0, a1, a1
xor a0, a0, t0
remu t0, t1, a2
lr.w t1, (s1)
addi t1, t1, 1
sc.w a1, t1, (s1)
srai t2, t2, 0
divu a1, a2, t0
lr.w a1, (s1)
addi a1, a1, 1
sc.w a2, a1, (s1)
ori s0, s0, -16
mulhu a1, s0, t2
sw s0, 4(s1)
sw s0, 12(s1)
lb a1, 0(s1)
or a0, a1, t2
j end_main
sub_22_0:
slt a1, s0, t1
slt t1, t2, s0
ret
end_main:
mv a0, s0
ecall
