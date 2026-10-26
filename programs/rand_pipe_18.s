li t0, -54
li t1, -69
li t2, 69
li a0, 14
li a1, -15
li a2, -39
li s0, -50
li s1, 256
sh a0, 4(s1)
slt a2, t0, t2
lb s0, 4(s1)
sltu a2, s0, t2
sh s0, 4(s1)
remu t2, t0, t2
sll a2, t2, a1
lh a1, 8(s1)
sb a1, 4(s1)
sw s0, 4(s1)
and a2, a1, a0
sltiu a0, a1, -13
lhu a1, 12(s1)
and t1, a1, a0
sb t0, 8(s1)
mulhu s0, t1, a0
sb s0, 0(s1)
jal ra, sub_18_0
srli s0, a0, 26
mulh a2, s0, a2
slti t2, t2, 13
beq a2, a1, skip_18_21
addi a0, a2, 1
skip_18_21: nop
csrrw a0, mscratch, t1
csrrs s0, mscratch, zero
srl a2, s0, a2
sra a1, a2, s0
sh a1, 12(s1)
remu a0, a1, a1
lr.w s0, (s1)
addi s0, s0, 1
sc.w s0, s0, (s1)
and t1, s0, s0
bge a2, t2, skip_18_29
addi a2, a2, 1
skip_18_29: nop
mulhu s0, a2, t2
sw a1, 4(s1)
sltu t0, s0, s0
lh s0, 0(s1)
lh t0, 0(s1)
lb t2, 12(s1)
lbu s0, 0(s1)
mulh a0, s0, s0
sub t2, a0, t2
mulh t1, t2, t1
lh a0, 8(s1)
remu a1, a0, s0
sw a2, 12(s1)
csrrw t2, mscratch, t1
csrrs s0, mscratch, zero
jal ra, sub_18_1
sh a0, 8(s1)
slli t0, a1, 13
sll a0, t0, s0
divu a1, t0, t2
sll t1, a1, a2
j end_main
sub_18_0:
or t1, a2, a2
xor a0, t0, a1
ret
sub_18_1:
mulh a2, a1, t1
srl t2, t1, a0
or a1, a1, t2
ret
end_main:
mv a0, s0
ecall
