li t0, -86
li t1, -77
li t2, -79
li a0, -8
li a1, -57
li a2, 88
li s0, 71
li s1, 256
lb a1, 12(s1)
lhu s0, 8(s1)
sh s0, 0(s1)
csrrw t2, mscratch, a0
csrrs t2, mscratch, zero
csrrw a0, mscratch, a1
csrrs t1, mscratch, zero
sw t0, 8(s1)
slt a1, t1, t2
lbu t1, 8(s1)
amoadd.w t2, t2, (s1)
jal ra, sub_2_1
divu a0, a2, a1
sh a1, 12(s1)
csrrw a0, mscratch, t2
csrrs a1, mscratch, zero
remu a1, a2, a0
lb t2, 8(s1)
rem a0, t2, t2
bge s0, a1, skip_2_16
addi a2, s0, 1
skip_2_16: nop
ori t1, a0, -45
amoadd.w t2, t0, (s1)
csrrw t1, mscratch, a2
csrrs t0, mscratch, zero
sltu a2, t0, t2
and t0, a2, a1
lr.w t1, (s1)
addi t1, t1, 1
sc.w t1, t1, (s1)
beq a0, a2, skip_2_23
addi t0, a0, 1
skip_2_23: nop
mul t2, t0, t1
add t0, t2, t0
divu t0, t2, t2
amoadd.w t1, t1, (s1)
sw a1, 4(s1)
sltu t0, t1, t2
lh a2, 12(s1)
mulhu a0, a2, a1
lbu t0, 4(s1)
srai t1, t0, 20
lr.w t0, (s1)
addi t0, t0, 1
sc.w s0, t0, (s1)
csrrw t1, mscratch, a1
csrrs a1, mscratch, zero
amoadd.w a0, t2, (s1)
sltu t2, a0, t2
j end_main
sub_2_0:
add a2, a2, a1
mul t1, t0, t2
and t0, t1, t1
ret
sub_2_1:
mul a0, t1, a1
add a2, t1, t1
ret
end_main:
mv a0, s0
ecall
