li t0, -81
li t1, 2
li t2, -90
li a0, 50
li a1, 50
li a2, -42
li s0, 62
li s1, 256
sw t0, 8(s1)
lb t0, 8(s1)
sw t0, 12(s1)
jal ra, sub_46_0
srai t0, a0, 7
srai t2, a1, 17
sltu a1, t2, t0
xori s0, a0, 13
addi s0, t1, -1
jal ra, sub_46_0
sll t2, s0, t0
sb s0, 4(s1)
div t1, t0, a0
div t2, t1, a1
lbu t1, 0(s1)
sw t1, 4(s1)
xori t0, t0, -19
xor a0, t0, s0
divu a0, a0, a2
amoadd.w a2, a0, (s1)
or t0, a2, t0
jal ra, sub_46_0
lh a2, 0(s1)
xori t2, a2, 14
slti t0, t1, 20
blt a2, a0, skip_46_25
addi s0, a2, 1
skip_46_25: nop
remu a1, a2, a1
blt s0, t2, skip_46_27
addi a2, s0, 1
skip_46_27: nop
lw a1, 4(s1)
lb a1, 0(s1)
sltiu t2, a1, -64
mulh a1, t2, a2
slti a1, t1, -34
lbu a2, 4(s1)
and t2, a2, a1
divu t2, a0, a2
andi t0, t1, 12
div t2, t2, a1
sb t2, 4(s1)
lbu a0, 12(s1)
mulhu a2, a0, a1
and t1, a2, t1
amoadd.w t0, a0, (s1)
mul s0, t0, s0
slt a1, s0, t0
xor s0, a1, t1
xori t2, a1, -27
sll t2, t2, t2
j end_main
sub_46_0:
and t1, t2, a2
or t0, a2, s0
sra a2, a2, t0
ret
end_main:
mv a0, s0
ecall
