li t0, -54
li t1, -69
li t2, 69
li a0, 14
li a1, -15
li s0, -39
li s1, 256
bne a0, t1, skip_18_7
addi s0, a0, 1
skip_18_7: nop
ori a0, t2, -34
and s0, t1, t1
slt s0, t2, a1
div s0, a0, t1
or t0, t2, a0
srai a0, a1, 17
sw t2, 0(s1)
slti t2, a0, -27
andi s0, t1, 47
sub a1, a0, a1
lw t1, 0(s1)
xori t2, s0, -42
addi a0, t1, -1
sltiu a1, t2, 36
sw a1, 0(s1)
sra t1, s0, t0
srl a0, t1, a0
div s0, a0, s0
rem t2, t2, s0
slti t1, a0, -60
lw a0, 0(s1)
slti s0, a0, 53
xori t0, a1, 39
andi a1, a0, -7
mul t1, t2, s0
mv a0, s0
ecall
