li t0, 38
li t1, -26
li t2, 56
li a0, -93
li a1, 59
li s0, 67
li s1, 256
bne a0, a0, skip_30_7
addi t0, a0, 1
skip_30_7: nop
slti t0, a0, -2
remu t1, a1, a1
remu s0, t2, a1
mul t0, t1, a1
mul a0, a1, t0
sra a1, t0, a1
lw t1, 0(s1)
div t0, t1, t1
slt t0, a0, s0
sra a1, s0, t1
ori a1, a0, 22
remu s0, t0, a0
ori a0, t2, -21
xori t1, a1, -7
lw a0, 0(s1)
lw a1, 0(s1)
bne s0, a0, skip_30_26
addi s0, s0, 1
skip_30_26: nop
sll s0, s0, a0
xor t1, s0, t1
andi t2, t0, -34
srai a1, t0, 16
sw a1, 0(s1)
and a0, s0, t0
sw t2, 0(s1)
rem a1, t1, t1
mv a0, s0
ecall
