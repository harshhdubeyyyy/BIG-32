li t0, 89
li t1, 19
li t2, 76
li a0, 91
li a1, 28
li a2, -72
li s0, 55
li s1, 256
srli a2, s0, 28
jal ra, sub_68_0
sll a2, a0, t0
or s0, a2, t1
remu t0, a1, s0
srai a0, a1, 1
lhu a2, 8(s1)
add s0, a2, t0
blt a0, s0, skip_68_8
addi a0, a0, 1
skip_68_8: nop
srl a0, a0, a0
and a2, a0, a0
lbu t0, 4(s1)
rem t0, t0, s0
rem s0, s0, s0
csrrw s0, mscratch, a1
csrrs t1, mscratch, zero
sb s0, 12(s1)
addi a2, t2, -57
lb s0, 8(s1)
lh t1, 12(s1)
csrrw a2, mscratch, t1
csrrs t0, mscratch, zero
amoadd.w t0, t2, (s1)
lw t1, 8(s1)
slt a0, t1, a0
csrrw t2, mscratch, s0
csrrs t2, mscratch, zero
sll t2, t2, a0
mulh a2, t2, t1
amoadd.w t2, t1, (s1)
lhu a0, 8(s1)
srli t0, a0, 30
sltu t1, t0, t2
addi a2, t0, 62
divu a2, a1, t1
csrrw t2, mscratch, a2
csrrs t2, mscratch, zero
lw a0, 0(s1)
lh a0, 8(s1)
lr.w t0, (s1)
addi t0, t0, 1
sc.w t1, t0, (s1)
bge t2, s0, skip_68_36
addi t1, t2, 1
skip_68_36: nop
sll t2, t1, t0
beq a0, t1, skip_68_38
addi t2, a0, 1
skip_68_38: nop
sltu t2, t2, a2
bge t2, t1, skip_68_40
addi a0, t2, 1
skip_68_40: nop
lw s0, 8(s1)
mul s0, s0, a1
j end_main
sub_68_0:
or t2, s0, a1
or s0, a1, t0
ret
end_main:
mv a0, s0
ecall
