li t0, 73
li t1, -89
li t2, 100
li a0, 33
li a1, -70
li a2, 30
li s0, -49
li s1, 256
jal ra, sub_19_1
sub a0, t2, t2
divu t2, t0, a1
csrrw t1, mscratch, t0
csrrs a1, mscratch, zero
slli s0, a2, 26
mulhu a1, s0, a0
lr.w a0, (s1)
addi a0, a0, 1
sc.w t2, a0, (s1)
sb t1, 12(s1)
sub a1, t2, a2
amoadd.w a0, t1, (s1)
mulh a0, a0, a1
slli a0, a0, 30
amoadd.w a0, a0, (s1)
csrrw s0, mscratch, t1
csrrs t0, mscratch, zero
sra t0, t0, a0
and a2, t0, t2
srai a0, a0, 10
slli t2, t2, 4
sub a2, t2, a0
srai a0, a1, 1
sub a2, a0, t0
sub a0, a2, a0
sub a0, a0, s0
srli a2, t1, 18
blt a1, a1, skip_19_24
addi t0, a1, 1
skip_19_24: nop
blt t2, a1, skip_19_25
addi t1, t2, 1
skip_19_25: nop
or s0, t1, a2
mulhu t2, s0, a0
sh a1, 8(s1)
lhu a2, 12(s1)
amoadd.w t0, s0, (s1)
lr.w t1, (s1)
addi t1, t1, 1
sc.w a0, t1, (s1)
lr.w t0, (s1)
addi t0, t0, 1
sc.w a1, t0, (s1)
lr.w t2, (s1)
addi t2, t2, 1
sc.w a0, t2, (s1)
lh a2, 4(s1)
srai s0, a2, 6
lbu a2, 0(s1)
csrrw t0, mscratch, a2
csrrs t2, mscratch, zero
srli a0, a1, 2
xori t2, t0, -56
jal ra, sub_19_0
j end_main
sub_19_0:
slt a1, t0, s0
sltu t0, a0, t0
mul a2, t1, a1
or t2, a1, a2
ret
sub_19_1:
add s0, t2, t1
or t1, t2, t0
sra a1, t1, t0
sra a2, t2, a1
ret
end_main:
mv a0, s0
ecall
