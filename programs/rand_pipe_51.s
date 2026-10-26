li t0, -38
li t1, 28
li t2, 41
li a0, -59
li a1, -38
li a2, -41
li s0, 41
li s1, 256
sb a2, 8(s1)
lbu t2, 0(s1)
lr.w t0, (s1)
addi t0, t0, 1
sc.w a1, t0, (s1)
and a0, a1, s0
sltiu t2, t2, -15
divu t0, a0, s0
srai t0, t0, 6
srl a0, t0, a2
bge t2, t0, skip_51_8
addi t1, t2, 1
skip_51_8: nop
csrrw a1, mscratch, s0
csrrs t1, mscratch, zero
lhu a0, 12(s1)
lhu a0, 0(s1)
jal ra, sub_51_0
sh a1, 0(s1)
slti a1, t0, 40
sb t1, 12(s1)
lw t1, 8(s1)
srai a1, t1, 28
jal ra, sub_51_1
mul s0, t1, a1
csrrw s0, mscratch, t1
csrrs t0, mscratch, zero
sltiu a2, t0, -24
lhu a2, 8(s1)
sh a2, 12(s1)
srai t0, a2, 17
srl a2, t0, a0
csrrw a2, mscratch, a0
csrrs t2, mscratch, zero
ori a1, a2, 53
xori a2, a1, -33
or t1, a2, s0
amoadd.w t2, a0, (s1)
rem t2, s0, t0
xor t2, t2, t0
bne a1, a0, skip_51_33
addi t0, a1, 1
skip_51_33: nop
xori t2, t0, -64
mulh s0, t2, t1
amoadd.w t0, a2, (s1)
divu t0, a1, a1
jal ra, sub_51_0
srl a1, a1, a0
sra t0, a1, a0
ori a1, t0, -45
j end_main
sub_51_0:
and t1, a2, t0
slt a1, t1, s0
sra s0, t2, t1
mulhu s0, s0, a0
ret
sub_51_1:
mul t0, t0, a0
or a1, t1, s0
ret
end_main:
mv a0, s0
ecall
