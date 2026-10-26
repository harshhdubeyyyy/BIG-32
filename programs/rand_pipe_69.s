li t0, 75
li t1, -91
li t2, -76
li a0, -58
li a1, -83
li a2, 54
li s0, -12
li s1, 256
xori s0, a0, 18
sh t1, 12(s1)
and t2, s0, t1
jal ra, sub_69_0
sub a0, a1, a2
sll s0, a0, a1
csrrw t0, mscratch, t0
csrrs t1, mscratch, zero
and t1, t1, t2
csrrw a2, mscratch, s0
csrrs t0, mscratch, zero
remu a2, t2, a1
xor t0, a2, t0
andi a2, s0, 61
lh a2, 4(s1)
bne a2, a0, skip_69_13
addi a2, a2, 1
skip_69_13: nop
lbu a0, 8(s1)
lh t0, 12(s1)
mulh s0, t0, a0
srli t0, a2, 13
srl s0, t0, s0
xori t1, a1, -26
add t0, t1, a1
sb t1, 8(s1)
mulhu a0, t0, t1
beq t0, s0, skip_69_23
addi a1, t0, 1
skip_69_23: nop
bge a2, s0, skip_69_24
addi a2, a2, 1
skip_69_24: nop
rem a1, a0, s0
sltu a0, a1, t2
amoadd.w t1, s0, (s1)
add t1, t1, t2
lb t0, 8(s1)
or t2, t0, s0
xori a1, a1, -37
sw t0, 12(s1)
sltiu a1, t2, 3
srli a2, t0, 10
mul s0, a2, t2
lbu a1, 8(s1)
xori t2, a1, -51
jal ra, sub_69_1
xori s0, s0, 11
ori a0, t2, -28
bge s0, t2, skip_69_41
addi a2, s0, 1
skip_69_41: nop
andi a2, a2, 1
divu t0, t0, a2
sub a0, t0, a2
sub a2, a0, t0
bne a1, s0, skip_69_46
addi t2, a1, 1
skip_69_46: nop
j end_main
sub_69_0:
xor a1, t2, t1
slt t2, t0, a0
ret
sub_69_1:
xor t1, a0, a0
mulhu t2, a1, t0
ret
end_main:
mv a0, s0
ecall
