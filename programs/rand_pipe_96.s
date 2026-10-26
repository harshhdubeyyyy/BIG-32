li t0, -6
li t1, -20
li t2, 72
li a0, 1
li a1, -48
li a2, -76
li s0, -13
li s1, 256
xor a2, t2, t0
jal ra, sub_96_0
lr.w a0, (s1)
addi a0, a0, 1
sc.w a0, a0, (s1)
srli t1, a2, 20
slt t0, t1, a0
amoadd.w t2, t1, (s1)
lh t0, 8(s1)
mulhu s0, t0, t1
srli s0, a1, 22
lr.w a1, (s1)
addi a1, a1, 1
sc.w a0, a1, (s1)
jal ra, sub_96_0
div s0, t2, t1
sb t1, 4(s1)
andi t0, a0, -48
add a0, t0, a2
div s0, a2, a2
slti a2, a2, 4
div t1, t1, t0
sub t2, t1, a2
sw s0, 4(s1)
lb t1, 8(s1)
lw s0, 0(s1)
sh s0, 8(s1)
xori t0, t1, 44
lbu t2, 0(s1)
lw a2, 4(s1)
lh a0, 4(s1)
andi t2, a0, 1
bne a0, a0, skip_96_28
addi a0, a0, 1
skip_96_28: nop
slt a1, a0, t2
j end_main
sub_96_0:
and t0, a0, a0
sub s0, t1, a0
or a2, t1, t0
ret
end_main:
mv a0, s0
ecall
