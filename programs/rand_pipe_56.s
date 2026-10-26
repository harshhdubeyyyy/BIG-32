li t0, 43
li t1, -98
li t2, 21
li a0, 67
li a1, 33
li a2, -23
li s0, 96
li s1, 256
mul a1, t0, t2
mulhu a1, a1, t0
sw a1, 12(s1)
lb t1, 0(s1)
lbu a1, 4(s1)
div t1, a1, a2
amoadd.w a1, t1, (s1)
mulh t1, a1, a0
lw t0, 8(s1)
add a1, t0, a2
sh a0, 8(s1)
srli t2, t1, 31
lh a2, 12(s1)
and t1, a2, t2
lw a0, 8(s1)
lr.w t1, (s1)
addi t1, t1, 1
sc.w s0, t1, (s1)
sb s0, 8(s1)
lw a0, 12(s1)
lhu a1, 4(s1)
srl a2, a1, a2
slt t1, a2, a1
amoadd.w t1, a2, (s1)
remu t0, t0, t0
xor a1, t0, t0
amoadd.w t1, a1, (s1)
beq s0, a2, skip_56_25
addi a1, s0, 1
skip_56_25: nop
jal ra, sub_56_0
and t0, s0, t2
sw t0, 12(s1)
divu a0, a2, t0
div t2, t0, s0
bge t0, t0, skip_56_31
addi t1, t0, 1
skip_56_31: nop
sw s0, 12(s1)
csrrw s0, mscratch, t1
csrrs a2, mscratch, zero
mulhu a1, a2, t2
xori t0, t2, 14
sltu a0, t0, a0
j end_main
sub_56_0:
xor a0, t1, a1
add a1, a2, a0
srl t0, t0, t2
ret
sub_56_1:
mulh a1, t1, t0
and a0, t1, a0
slt t2, s0, t0
ret
end_main:
mv a0, s0
ecall
