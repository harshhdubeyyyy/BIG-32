li t0, -34
li t1, -26
li t2, 75
li a0, 75
li a1, -53
li a2, 66
li s0, -41
li s1, 256
lhu t1, 4(s1)
divu t0, t1, a0
lr.w a1, (s1)
addi a1, a1, 1
sc.w t2, a1, (s1)
lr.w t0, (s1)
addi t0, t0, 1
sc.w s0, t0, (s1)
amoadd.w s0, s0, (s1)
srli a0, t1, 22
lr.w a0, (s1)
addi a0, a0, 1
sc.w a1, a0, (s1)
sh t2, 8(s1)
lh t2, 12(s1)
sh t2, 12(s1)
sb t1, 8(s1)
xor a0, t2, a1
slti t1, a1, -4
sw t2, 0(s1)
slli a2, a0, 27
bge t1, t1, skip_13_15
addi t0, t1, 1
skip_13_15: nop
amoadd.w s0, a2, (s1)
xor a2, s0, a2
csrrw s0, mscratch, t2
csrrs t1, mscratch, zero
divu a2, t2, a1
csrrw a2, mscratch, a1
csrrs t1, mscratch, zero
div t1, s0, a1
lhu a1, 8(s1)
mulhu t1, a1, t1
lw t0, 12(s1)
lhu a1, 0(s1)
jal ra, sub_13_0
sh t0, 8(s1)
csrrw a1, mscratch, a1
csrrs a2, mscratch, zero
add a0, a2, t2
slt t2, a0, a0
jal ra, sub_13_0
lbu t2, 4(s1)
divu t2, t2, a0
mulhu a1, t2, t2
mul t2, a1, t1
xori t0, t2, -42
j end_main
sub_13_0:
add s0, a1, t0
mulhu a2, t2, t1
ret
end_main:
mv a0, s0
ecall
