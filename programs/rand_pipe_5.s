li t0, 59
li t1, -35
li t2, 89
li a0, -9
li a1, 76
li a2, 89
li s0, 66
li s1, 256
divu t1, a2, t0
srl a0, t1, t1
sb t0, 4(s1)
xori t1, s0, -24
remu t0, t1, a1
or t0, t0, t0
rem t1, s0, t1
sltiu t1, a1, -12
xor a2, t1, a0
xor a0, a2, t1
sltu t2, a0, a1
sub a2, t2, t2
sltiu s0, t2, 16
add a0, s0, t1
srl t0, a0, t2
srl s0, t0, t2
sb t0, 4(s1)
lb t1, 12(s1)
ori t2, t1, 54
sll a2, t2, s0
lr.w t0, (s1)
addi t0, t0, 1
sc.w t0, t0, (s1)
and a1, t0, t2
ori a2, a1, 17
andi s0, t0, 15
jal ra, sub_5_0
jal ra, sub_5_0
remu t2, s0, t2
lw t1, 12(s1)
sltiu t1, t1, -31
lb s0, 12(s1)
xori t0, s0, 11
slt a1, t0, t1
srli a0, a2, 30
sub a0, a0, t1
xori a1, t1, 22
mulhu a0, a1, a1
sh t0, 0(s1)
rem t2, a1, a2
lr.w t2, (s1)
addi t2, t2, 1
sc.w a2, t2, (s1)
div t2, a2, t1
srai s0, t2, 17
srai s0, a1, 22
xori a2, t2, 25
bge s0, s0, skip_5_43
addi t1, s0, 1
skip_5_43: nop
j end_main
sub_5_0:
slt t2, t1, a1
or t1, s0, t2
sra s0, t2, a2
ret
end_main:
mv a0, s0
ecall
