li t0, -97
li t1, 20
li t2, -72
li a0, 95
li a1, 0
li a2, -64
li s0, 75
li s1, 256
bne t1, a2, skip_31_0
addi a1, t1, 1
skip_31_0: nop
add a2, a1, a2
slt a1, a2, a0
addi a1, t0, 39
ori t1, t2, -1
mul t1, t1, a1
sh t1, 4(s1)
add s0, t1, a0
mul a1, s0, a0
amoadd.w t1, a0, (s1)
divu t1, t2, a2
sh t2, 12(s1)
sw t2, 0(s1)
amoadd.w t2, a1, (s1)
lh a1, 0(s1)
sltu t0, a1, s0
ori t0, a2, 14
lb t1, 8(s1)
srai s0, t1, 7
or s0, s0, t0
and t1, s0, s0
srai a0, a1, 17
lr.w a1, (s1)
addi a1, a1, 1
sc.w a2, a1, (s1)
lb s0, 12(s1)
jal ra, sub_31_0
sw t2, 0(s1)
and a1, t2, a0
jal ra, sub_31_0
blt s0, t1, skip_31_28
addi t1, s0, 1
skip_31_28: nop
lhu a1, 12(s1)
sltu t1, a1, a2
srli a2, s0, 8
sltiu a1, s0, -15
bne a0, a1, skip_31_33
addi a2, a0, 1
skip_31_33: nop
j end_main
sub_31_0:
mul s0, t0, a2
or a0, t1, t1
ret
end_main:
mv a0, s0
ecall
