li t0, 15
li t1, 49
li t2, 11
li a0, 16
li a1, -90
li a2, 86
li s0, 96
li s1, 256
mulhu a2, t2, t0
mul a0, a2, s0
xori a2, a0, -57
xori a1, a1, -14
sltu t1, a1, a0
sltu a0, t1, t2
rem t0, t0, t2
sub t0, t0, a0
amoadd.w t2, a2, (s1)
sltu a0, t2, t2
lw s0, 0(s1)
blt s0, a0, skip_75_11
addi t2, s0, 1
skip_75_11: nop
slt t1, t2, a1
srli t2, a1, 11
sltiu s0, a0, 61
remu a0, t2, t2
lr.w t2, (s1)
addi t2, t2, 1
sc.w t2, t2, (s1)
slti t2, t0, 60
amoadd.w a1, t2, (s1)
slti t0, s0, -31
csrrw t0, mscratch, a0
csrrs a1, mscratch, zero
amoadd.w a1, t2, (s1)
amoadd.w t2, s0, (s1)
or a1, t2, s0
jal ra, sub_75_1
lw a2, 12(s1)
rem s0, a2, t0
sra t2, s0, t2
slli a1, t1, 25
amoadd.w t2, t1, (s1)
csrrw t1, mscratch, a1
csrrs t0, mscratch, zero
lr.w t2, (s1)
addi t2, t2, 1
sc.w s0, t2, (s1)
sw a0, 8(s1)
sra a2, s0, t2
remu a2, s0, t1
srl t0, a2, t0
amoadd.w t1, t2, (s1)
or a1, t1, t0
divu a1, t2, t2
addi a1, t1, 31
or t1, a1, t1
j end_main
sub_75_0:
srl t1, t0, a1
xor s0, a0, a2
mul a0, t1, t1
sub a2, a0, t1
ret
sub_75_1:
and s0, a0, t1
mulh s0, t2, t1
mul t0, a1, a0
ret
end_main:
mv a0, s0
ecall
