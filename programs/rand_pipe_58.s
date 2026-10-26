li t0, 48
li t1, -50
li t2, -48
li a0, 89
li a1, 64
li a2, -49
li s0, -90
li s1, 256
xori t2, s0, 43
xori a1, t0, -10
srai t0, a0, 24
lb t0, 8(s1)
xor s0, t0, t2
mulhu a1, s0, t1
lbu t0, 4(s1)
add a2, t0, t1
sub t2, a2, a2
srli s0, a2, 21
lb t1, 12(s1)
csrrw a1, mscratch, t1
csrrs t1, mscratch, zero
slli a1, t0, 31
remu t2, a2, a0
mulh a0, t2, s0
csrrw t1, mscratch, t0
csrrs a1, mscratch, zero
or t2, a1, t0
sw a0, 8(s1)
lh s0, 8(s1)
sw s0, 4(s1)
sll a2, s0, a2
andi a2, s0, -12
div a2, a1, t1
sll a1, a2, t0
amoadd.w t2, s0, (s1)
sw t2, 12(s1)
lbu a2, 12(s1)
mulhu t0, a2, a1
lb t1, 0(s1)
div a2, t1, a0
slt a2, a2, t0
slti t1, t2, 54
csrrw s0, mscratch, s0
csrrs a0, mscratch, zero
sw t2, 8(s1)
add t0, a0, a1
amoadd.w a1, a0, (s1)
and t0, a1, t2
jal ra, sub_58_0
sltiu t2, t1, -12
srli t2, a1, 5
lr.w a2, (s1)
addi a2, a2, 1
sc.w a2, a2, (s1)
jal ra, sub_58_0
jal ra, sub_58_0
sw a0, 4(s1)
j end_main
sub_58_0:
mulhu t1, t1, t0
slt a0, a1, s0
slt a0, t1, a0
ret
end_main:
mv a0, s0
ecall
