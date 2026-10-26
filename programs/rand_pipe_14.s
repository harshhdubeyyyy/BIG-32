li t0, -73
li t1, 57
li t2, 79
li a0, 93
li a1, 66
li a2, 34
li s0, -37
li s1, 256
ori t0, a2, 55
lw a0, 8(s1)
mulhu t2, a0, t2
slt s0, t2, a2
xor a1, s0, a2
sltu a2, a1, t0
xori t0, t2, 39
lw a0, 8(s1)
sra t0, a0, a2
sb a0, 4(s1)
sw t2, 0(s1)
amoadd.w t0, t2, (s1)
sub t1, t0, a0
lbu a1, 4(s1)
sh a1, 12(s1)
srli a1, s0, 30
xori a0, s0, -47
sb t2, 12(s1)
add a2, a0, a0
ori a1, t2, 27
slti t1, t0, 56
amoadd.w t0, t0, (s1)
sltu t2, t0, t0
sh t2, 0(s1)
add t1, t2, t1
and s0, t1, t2
xor a1, s0, t2
divu t2, t0, a1
sh t2, 12(s1)
mulhu a0, t2, a1
csrrw a0, mscratch, a1
csrrs t0, mscratch, zero
sll a0, t0, s0
or s0, a0, t1
sra t1, s0, t2
slli a1, a0, 16
divu a1, a0, a0
srai t0, t1, 11
mul a2, t0, a2
j end_main
sub_14_0:
mul a1, s0, a1
add a2, a1, a0
xor a0, a0, t2
ret
sub_14_1:
sll s0, t0, a2
mul a2, a1, s0
ret
end_main:
mv a0, s0
ecall
