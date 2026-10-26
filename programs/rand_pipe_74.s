li t0, 56
li t1, 31
li t2, -71
li a0, -19
li a1, -70
li a2, -21
li s0, -54
li s1, 256
xor s0, a0, a1
srai t2, t2, 0
lb t0, 12(s1)
or a1, t0, a0
add a2, a1, a0
sw a2, 0(s1)
div a2, t2, t0
mulh s0, a2, a0
sb t1, 4(s1)
lbu s0, 12(s1)
lw t1, 12(s1)
lr.w t1, (s1)
addi t1, t1, 1
sc.w a0, t1, (s1)
xor t2, a0, t0
lh a1, 8(s1)
or s0, a1, t0
sh a1, 12(s1)
csrrw s0, mscratch, t1
csrrs a2, mscratch, zero
remu t0, a2, t0
xor a1, t0, t2
sb s0, 12(s1)
lbu a2, 0(s1)
addi s0, a2, -16
slt a0, s0, s0
lb a1, 8(s1)
remu t2, a1, a0
or a1, t2, t1
amoadd.w a2, t1, (s1)
rem a0, a2, a1
srl t1, a0, a1
add t0, t1, t1
amoadd.w t2, t1, (s1)
or t1, t2, a1
mul t1, t1, s0
divu t0, t1, s0
slt a0, t0, a2
blt t2, t2, skip_74_35
addi a1, t2, 1
skip_74_35: nop
divu t2, a1, t2
sra t2, t2, a1
sw a0, 4(s1)
srai t0, a2, 24
srli t0, a0, 30
j end_main
sub_74_0:
sra a0, a1, t1
mulh t0, a2, a0
sub a2, t0, a2
sll t0, a0, a2
ret
end_main:
mv a0, s0
ecall
