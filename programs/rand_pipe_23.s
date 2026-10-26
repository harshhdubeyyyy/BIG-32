li t0, 99
li t1, -26
li t2, -79
li a0, -96
li a1, 51
li a2, -22
li s0, 8
li s1, 256
xori a2, t1, -61
sub a0, a2, t0
jal ra, sub_23_1
addi t0, t1, 30
lh a1, 8(s1)
jal ra, sub_23_1
sb t1, 12(s1)
lb a0, 4(s1)
amoadd.w a1, t2, (s1)
lw a1, 0(s1)
xor t0, a1, a1
blt s0, a1, skip_23_11
addi t2, s0, 1
skip_23_11: nop
mulhu t2, t2, t2
slli t1, t2, 7
rem s0, a0, t1
sh t0, 4(s1)
srli t0, t0, 25
add s0, t0, a2
jal ra, sub_23_1
remu t2, t0, s0
sh t2, 4(s1)
div a0, t2, t1
mulh a1, a0, t1
sw t2, 12(s1)
sll t0, a1, s0
lhu a0, 12(s1)
mulh s0, a0, a2
xor t2, s0, a0
div a1, a1, a1
amoadd.w t0, a2, (s1)
srl a1, t0, s0
slt a2, a1, t2
lbu t0, 12(s1)
jal ra, sub_23_1
xori s0, t1, -12
amoadd.w t0, a2, (s1)
srai a0, t0, 17
sb a2, 4(s1)
sw t0, 0(s1)
lr.w a0, (s1)
addi a0, a0, 1
sc.w s0, a0, (s1)
xor a0, s0, a0
lh a0, 8(s1)
bge a0, t1, skip_23_42
addi t2, a0, 1
skip_23_42: nop
mulhu s0, t2, a0
sb t2, 0(s1)
slti t2, s0, 30
j end_main
sub_23_0:
sra a1, t0, t2
mulhu a1, a0, t0
ret
sub_23_1:
mulhu t2, s0, t0
mulhu t1, a1, a2
ret
end_main:
mv a0, s0
ecall
