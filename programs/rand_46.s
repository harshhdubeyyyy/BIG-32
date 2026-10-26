li t0, -81
li t1, 2
li t2, -90
li a0, 50
li a1, 50
li s0, -42
li s1, 256
addi a1, a1, -47
sw t0, 0(s1)
div t2, a1, t2
lw t0, 0(s1)
addi t1, a0, 53
srli a1, a1, 14
and a0, s0, t2
sll t2, t0, a1
ori a0, t1, 27
slli t1, t0, 20
slt t2, t0, t2
mul a1, s0, a1
andi t1, s0, -48
sltu s0, t2, t1
srl s0, t1, t2
sltiu t0, a1, -56
sub t1, t2, t0
divu s0, t1, t1
sra t2, s0, s0
xor t1, a0, s0
add a0, t0, t0
xor t0, a0, t2
addi s0, a1, 39
xor a0, a0, t2
ori t1, t0, 36
remu t0, a1, s0
ori t0, s0, 47
sltiu t0, t0, -12
add t2, t1, s0
div a1, s0, s0
sub a1, t1, a1
xori s0, s0, -27
div t2, a1, t1
andi t2, a0, 9
lw t1, 0(s1)
sltu t2, t2, t2
slli a1, s0, 31
andi a1, t2, 42
xori s0, a0, -18
lw a1, 0(s1)
mv a0, s0
ecall
