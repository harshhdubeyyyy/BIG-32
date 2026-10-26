li t0, -86
li t1, -77
li t2, -79
li a0, -8
li a1, -57
li s0, 88
li s1, 256
sltu t1, a1, t0
sltiu a0, s0, 31
addi a0, a1, -57
remu t2, a0, a0
lw t1, 0(s1)
and t0, t1, t2
mul a1, t2, a1
slti a0, a0, 29
sw a0, 0(s1)
sra a0, s0, s0
xori t1, a0, 26
slti a0, a0, 52
andi t1, t2, 4
srai a0, t2, 26
sll t1, a0, a1
lw a1, 0(s1)
slli t1, s0, 3
divu t1, s0, t0
addi t2, t1, 44
lw t0, 0(s1)
sub t1, s0, t0
div t0, t0, t0
lw t2, 0(s1)
sw t1, 0(s1)
addi t0, a0, -1
sltu t0, t0, t2
ori s0, t0, 61
div a0, a1, a1
div t2, a0, a1
mv a0, s0
ecall
