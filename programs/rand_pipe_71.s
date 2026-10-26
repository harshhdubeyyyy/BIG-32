li t0, -18
li t1, 30
li t2, 58
li a0, -98
li a1, -33
li a2, -61
li s0, 93
li s1, 256
or a1, t0, a1
sh a1, 12(s1)
div t2, a2, t1
slti t0, a0, -16
jal ra, sub_71_0
bne t0, t1, skip_71_5
addi a2, t0, 1
skip_71_5: nop
slt s0, a2, s0
ori a1, t0, -11
addi t0, t0, 11
sltu a0, t0, s0
lb t2, 8(s1)
lbu t1, 12(s1)
sb t1, 8(s1)
divu s0, t0, t0
slt t2, s0, s0
amoadd.w s0, t1, (s1)
slt t1, s0, a0
slli t1, a1, 28
xor a0, t1, s0
slti a1, a2, 60
sh s0, 4(s1)
srai a2, a1, 18
lw t0, 8(s1)
mulh a1, t0, s0
slt a0, a1, a1
lr.w a1, (s1)
addi a1, a1, 1
sc.w t0, a1, (s1)
sltiu t0, a1, 8
ori a2, a1, -59
amoadd.w a0, a0, (s1)
lw t2, 12(s1)
lh t0, 12(s1)
mul a2, t0, s0
sh t1, 12(s1)
slli a1, s0, 4
sw t1, 4(s1)
sll a0, a1, t0
and a0, a0, t1
div t1, a2, s0
j end_main
sub_71_0:
add a1, t0, t0
srl t2, t0, a2
mul t2, s0, a2
ret
end_main:
mv a0, s0
ecall
