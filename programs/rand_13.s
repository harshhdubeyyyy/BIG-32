li t0, -34
li t1, -26
li t2, 75
li a0, 75
li a1, -53
li s0, 66
li s1, 256
andi t1, s0, -31
add t1, s0, t2
xor s0, a1, t0
sw a0, 0(s1)
slli t1, t2, 31
lw a1, 0(s1)
sltiu a0, s0, -34
div a1, s0, t2
sra a1, s0, t1
ori a0, a1, -13
sra t2, t2, t2
sltu t2, a0, t1
andi t1, a1, 29
sra a0, s0, s0
or s0, a0, t0
xor s0, a0, s0
remu a0, s0, t2
srai t2, t1, 23
slti s0, t1, -4
srai t1, a1, 2
and s0, a1, t2
sub t1, s0, a1
lw t1, 0(s1)
addi a1, a1, 48
sw a1, 0(s1)
xor t2, t0, a0
lw a1, 0(s1)
mv a0, s0
ecall
