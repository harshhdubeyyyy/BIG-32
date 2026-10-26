li t0, -65
li t1, -38
li t2, -94
li a0, 56
li a1, 14
li s0, -53
li s1, 256
srli t2, t0, 3
mul a1, t1, a1
srai a0, s0, 1
andi t2, a0, -36
sltiu s0, a1, 19
ori t2, t1, -28
and t2, s0, s0
srl t2, a1, t0
lw a1, 0(s1)
lw a0, 0(s1)
add t2, a0, a1
slt a1, a1, a1
sub s0, a1, a0
srl a0, t2, t0
sw a1, 0(s1)
remu t0, t0, a0
sll t0, a1, a0
sra t2, s0, t1
div a1, t1, s0
or s0, t0, t0
add t1, a1, a0
sw a1, 0(s1)
rem t2, s0, s0
mv a0, s0
ecall
