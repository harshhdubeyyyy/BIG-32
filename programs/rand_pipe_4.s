li t0, -40
li t1, -23
li t2, -74
li a0, 84
li a1, 1
li a2, 22
li s0, -61
li s1, 256
mulhu a1, t2, s0
xor a1, a1, t2
divu s0, t0, t2
blt s0, a2, skip_4_3
addi t0, s0, 1
skip_4_3: nop
amoadd.w t1, t2, (s1)
ori s0, a2, -42
lr.w t2, (s1)
addi t2, t2, 1
sc.w a0, t2, (s1)
sh a0, 0(s1)
blt s0, a1, skip_4_8
addi s0, s0, 1
skip_4_8: nop
xor t2, s0, a2
lr.w a1, (s1)
addi a1, a1, 1
sc.w a0, a1, (s1)
slli t2, a0, 14
addi s0, s0, -53
srai t2, a1, 30
div t1, a2, t1
xori t1, a2, 6
sll a0, t1, a1
lw t1, 4(s1)
or a1, t1, a1
add t1, a1, a0
mulh a2, t1, t2
lh t2, 8(s1)
jal ra, sub_4_0
lr.w s0, (s1)
addi s0, s0, 1
sc.w a2, s0, (s1)
amoadd.w t2, t1, (s1)
csrrw t2, mscratch, t1
csrrs t2, mscratch, zero
addi t1, t2, 29
mulhu t1, t1, s0
xori t2, a1, -11
slli t1, t0, 3
div a1, a2, t1
sw t2, 0(s1)
j end_main
sub_4_0:
mulhu t2, a0, a2
sra t1, t1, t1
srl a0, a0, t0
srl t1, a0, t1
ret
end_main:
mv a0, s0
ecall
