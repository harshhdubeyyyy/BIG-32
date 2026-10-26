li t0, -49
li t1, 79
li t2, 57
li a0, -73
li a1, -18
li a2, -51
li s0, -44
li s1, 256
lhu a2, 4(s1)
remu a1, a2, a1
lhu t0, 0(s1)
srli a1, t0, 30
lb a2, 12(s1)
lb t0, 0(s1)
sltiu t1, t0, -6
sll s0, t1, a2
blt t1, t0, skip_85_8
addi s0, t1, 1
skip_85_8: nop
sll t1, s0, t1
slli s0, t1, 23
lh s0, 4(s1)
slli t0, s0, 17
addi t1, s0, 24
andi a1, s0, -20
jal ra, sub_85_1
addi t1, a1, 37
divu a2, s0, t0
sb a2, 8(s1)
mulh a2, a2, a0
srai t2, a1, 15
mul a2, t2, a1
sb a0, 8(s1)
csrrw a0, mscratch, t1
csrrs a0, mscratch, zero
lb a0, 12(s1)
andi t2, a0, -15
lw t0, 4(s1)
amoadd.w a0, t0, (s1)
slt t1, a0, t2
sw s0, 4(s1)
sw t2, 0(s1)
and t1, t1, t1
sltiu t1, t2, 13
sub s0, t1, t0
csrrw s0, mscratch, t2
csrrs t1, mscratch, zero
xor t0, t1, a0
or s0, t0, a2
mulhu t1, s0, t2
lw a0, 0(s1)
sltiu t2, a0, -59
sh a1, 12(s1)
j end_main
sub_85_0:
mul t1, a1, a0
sra a1, a1, a1
mulh a1, t1, a2
ret
sub_85_1:
srl a0, s0, t2
sll t1, t1, t2
sll t1, s0, s0
srl t2, a0, t2
ret
end_main:
mv a0, s0
ecall
