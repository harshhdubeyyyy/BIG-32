li t0, -81
li t1, -71
li t2, 96
li a0, 4
li a1, 19
li a2, 6
li s0, -32
li s1, 256
lb t1, 8(s1)
sub a0, t1, t1
lbu a0, 0(s1)
sltiu a1, a0, -23
jal ra, sub_67_1
remu s0, t1, a2
amoadd.w t2, a0, (s1)
sh s0, 8(s1)
and t1, t2, t0
lw a2, 12(s1)
bge a2, s0, skip_67_10
addi t2, a2, 1
skip_67_10: nop
add t1, t2, a1
lhu a2, 0(s1)
lbu t0, 12(s1)
divu t1, t0, t0
sh t1, 0(s1)
sb a1, 12(s1)
lh s0, 0(s1)
lw s0, 4(s1)
srli t1, s0, 18
lhu a1, 0(s1)
rem t2, a1, a1
and a2, t2, t1
srai t0, s0, 22
mul t0, t0, t2
lw s0, 8(s1)
lh a2, 4(s1)
lr.w t0, (s1)
addi t0, t0, 1
sc.w t1, t0, (s1)
slli s0, t0, 30
addi a2, a1, -33
srli a2, a2, 19
bne a1, a1, skip_67_31
addi t2, a1, 1
skip_67_31: nop
ori t1, a2, -61
sub t1, t1, a1
xori a1, t0, -47
amoadd.w a1, t0, (s1)
xori a2, a2, -48
slli t2, a0, 21
slti t2, t1, -32
sh a0, 4(s1)
add a1, t2, t0
lb t1, 4(s1)
sh t1, 4(s1)
blt a1, t2, skip_67_43
addi t2, a1, 1
skip_67_43: nop
rem t1, t2, t2
j end_main
sub_67_0:
add a1, a0, t1
mulhu s0, t0, a0
sltu a1, t0, a1
ret
sub_67_1:
xor a0, t0, t0
slt t0, s0, a0
sll a1, s0, a0
ret
end_main:
mv a0, s0
ecall
