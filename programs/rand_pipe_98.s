li t0, -9
li t1, 47
li t2, -89
li a0, -10
li a1, 7
li a2, -85
li s0, 21
li s1, 256
add a0, t1, a0
lh s0, 0(s1)
remu s0, s0, t0
remu t2, t0, a2
srl s0, t2, t1
xor a1, s0, t1
lb t1, 12(s1)
sw t1, 12(s1)
mulh t2, t1, t1
addi t0, s0, 50
div a1, s0, t2
sh t1, 8(s1)
jal ra, sub_98_0
lbu t0, 8(s1)
srai a0, t0, 17
addi t1, a2, 20
sb a2, 0(s1)
csrrw a0, mscratch, a2
csrrs s0, mscratch, zero
sub a0, s0, a1
jal ra, sub_98_1
mul a0, a2, t1
sh a0, 12(s1)
xori s0, s0, -59
slli a1, a2, 3
mulh a1, a1, a0
sw a1, 8(s1)
srai s0, a1, 7
slti a2, t2, -6
srl t0, a2, a0
mul a1, t0, s0
mulhu a1, a1, t2
lr.w t0, (s1)
addi t0, t0, 1
sc.w t0, t0, (s1)
slti t1, t0, -4
amoadd.w s0, t2, (s1)
sb t1, 0(s1)
sra t1, s0, a0
div s0, t0, a1
amoadd.w a1, a1, (s1)
bge t2, t1, skip_98_38
addi t0, t2, 1
skip_98_38: nop
ori t0, a2, 40
sltiu s0, t0, -11
xor a0, s0, t2
xori s0, a0, 5
rem a2, a2, t0
mul a1, a2, a2
lr.w a1, (s1)
addi a1, a1, 1
sc.w s0, a1, (s1)
csrrw a2, mscratch, s0
csrrs t1, mscratch, zero
j end_main
sub_98_0:
and t0, t1, a0
or a1, a0, a1
add a1, t2, t1
ret
sub_98_1:
srl t2, t1, a2
slt a1, a0, a1
slt t0, s0, a0
sub t2, a1, t0
ret
end_main:
mv a0, s0
ecall
