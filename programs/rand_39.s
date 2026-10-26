li t0, -47
li t1, -34
li t2, -2
li a0, -94
li a1, -51
li s0, -44
li s1, 256
srai t0, s0, 22
slli t0, t2, 23
divu a0, t2, a0
srli a0, a1, 17
srai a0, a0, 20
sltiu s0, s0, -16
lw a1, 0(s1)
srli a0, t2, 22
andi a1, a0, 12
lw t2, 0(s1)
srli t0, a0, 5
mul t0, s0, s0
mul a1, a1, a1
sltu t1, s0, a1
or a1, a0, s0
andi t1, s0, -42
ori a0, t2, -9
sw t1, 0(s1)
xor t1, t2, t2
sub t0, t1, a1
lw t0, 0(s1)
lw t0, 0(s1)
andi t2, t2, -32
rem t2, a1, t0
slt t0, t2, t0
and t1, t1, a0
sltiu t1, t2, -10
sll s0, t1, t2
xori a0, t2, -4
slti t0, a1, -45
mul t1, t0, a1
andi t0, t2, -42
mv a0, s0
ecall
