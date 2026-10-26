li t0, -66
li t1, 45
li t2, 95
li a0, -84
li a1, -35
li a2, -70
li s0, 26
li s1, 256
lbu s0, 0(s1)
csrrw a0, mscratch, s0
csrrs a0, mscratch, zero
lbu s0, 8(s1)
div t1, s0, a1
csrrw t0, mscratch, t0
csrrs t0, mscratch, zero
lb t0, 12(s1)
remu a1, t0, t1
bne t1, t2, skip_1_7
addi a1, t1, 1
skip_1_7: nop
lw s0, 12(s1)
lr.w a1, (s1)
addi a1, a1, 1
sc.w a2, a1, (s1)
xor a2, a2, s0
slt t2, a2, a2
bne a1, s0, skip_1_12
addi a0, a1, 1
skip_1_12: nop
slti a1, a0, 36
lbu t0, 12(s1)
lh t2, 0(s1)
slli a1, t2, 25
addi a2, t0, 14
remu a1, a1, a1
lw t1, 4(s1)
sw t1, 12(s1)
sh t2, 8(s1)
lbu a1, 4(s1)
sh a1, 0(s1)
sw a1, 12(s1)
sw t2, 8(s1)
srai t0, s0, 11
sb t0, 8(s1)
add a2, t0, t0
slli s0, s0, 17
xor a1, s0, t2
and t1, a1, a1
lbu a2, 8(s1)
sh a2, 12(s1)
addi s0, t1, 0
csrrw a1, mscratch, t1
csrrs a1, mscratch, zero
srli t0, t1, 9
slt t1, t0, a2
lhu a1, 12(s1)
srl a2, a1, t0
lbu s0, 0(s1)
div t1, s0, t1
ori s0, t0, -24
slti t2, t1, -55
lb t1, 0(s1)
j end_main
sub_1_0:
sll t1, t0, t1
mul a1, a0, a1
sra t1, t0, a2
ret
sub_1_1:
slt t2, a0, t0
sltu t2, s0, a0
add t2, t1, t1
ret
end_main:
mv a0, s0
ecall
