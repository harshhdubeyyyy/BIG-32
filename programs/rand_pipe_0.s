li t0, -2
li t1, 94
li t2, 7
li a0, -90
li a1, -34
li a2, 30
li s0, 24
li s1, 256
jal ra, sub_0_0
ori s0, t0, -27
sltiu a2, t0, 20
srli t0, t2, 13
jal ra, sub_0_1
mulh a1, t0, t0
lr.w a2, (s1)
addi a2, a2, 1
sc.w s0, a2, (s1)
lh t0, 4(s1)
div a2, t0, s0
mulhu a1, a2, t1
jal ra, sub_0_0
sub t2, a1, a0
slti t2, a2, 21
amoadd.w a1, s0, (s1)
lw a1, 12(s1)
andi t1, a1, -16
amoadd.w t0, a2, (s1)
mulhu t0, t0, a2
sub t1, t0, s0
csrrw s0, mscratch, a1
csrrs a2, mscratch, zero
slti a2, a1, -4
lr.w a2, (s1)
addi a2, a2, 1
sc.w s0, a2, (s1)
bge t2, a0, skip_0_22
addi a1, t2, 1
skip_0_22: nop
lw a2, 8(s1)
lh a0, 4(s1)
sub a2, a0, t2
rem t2, s0, t1
slli t0, t0, 14
sltu a1, t0, a1
lb t0, 0(s1)
addi t2, t0, -55
lw t1, 12(s1)
mul s0, t1, t0
xor a0, s0, t0
sll t0, a0, t2
slli t0, a1, 6
lh a0, 12(s1)
lr.w a1, (s1)
addi a1, a1, 1
sc.w t1, a1, (s1)
lb t1, 4(s1)
j end_main
sub_0_0:
xor a1, t0, a1
mul a0, t1, t0
mul a0, a0, a1
ret
sub_0_1:
mul t2, t2, a0
mul s0, t2, t1
mulh a1, t0, a0
sub a2, t2, a2
ret
end_main:
mv a0, s0
ecall
