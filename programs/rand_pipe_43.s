li t0, -91
li t1, -27
li t2, 78
li a0, 95
li a1, -64
li a2, 18
li s0, -6
li s1, 256
lbu a1, 8(s1)
lbu a1, 12(s1)
sub s0, a1, t0
xori t0, t1, -32
divu a1, a1, t2
andi t0, a1, -49
lr.w t2, (s1)
addi t2, t2, 1
sc.w t0, t2, (s1)
sb s0, 0(s1)
mul a1, t0, s0
csrrw t2, mscratch, t2
csrrs a1, mscratch, zero
lw a0, 8(s1)
sll a1, a0, t2
div a2, a1, t0
sltiu s0, a2, 47
sub a0, s0, s0
sltiu a2, t0, -25
sb a2, 12(s1)
slli t0, t1, 7
mulhu t0, t0, s0
ori a2, a1, 52
lr.w s0, (s1)
addi s0, s0, 1
sc.w t0, s0, (s1)
remu t0, a2, t1
sltu a1, t0, t2
lh s0, 0(s1)
or t1, s0, s0
rem t0, a2, t1
srl t1, t0, t1
amoadd.w a0, t0, (s1)
slli t0, t0, 7
sh t1, 12(s1)
or t0, t0, a2
srl a1, t0, t1
slli t0, t1, 21
slti a1, t1, -26
lw t1, 8(s1)
srai t2, t1, 4
sw t2, 0(s1)
rem a0, a2, t1
sh a2, 12(s1)
xori s0, a2, 45
div a1, s0, a1
and a2, a1, a2
lw t0, 4(s1)
mulhu t1, t0, a1
j end_main
sub_43_0:
slt s0, t0, t2
sra t1, a0, a0
sub t2, t2, a0
mulh a0, t2, a0
ret
end_main:
mv a0, s0
ecall
