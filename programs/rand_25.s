li t0, -4
li t1, 96
li t2, -97
li a0, -46
li a1, -22
li s0, 62
li s1, 256
sltu t2, t0, t2
mul a1, t0, a1
srli t1, a1, 11
addi a1, a0, -39
andi t2, a0, -23
slti t0, t0, -47
slti t1, s0, -20
rem a1, t1, a0
slti a0, a0, 59
add a0, t2, t1
bne s0, a0, skip_25_17
addi a0, s0, 1
skip_25_17: nop
sltu t1, a0, a1
sub t0, t1, t0
or t1, s0, t1
lw t2, 0(s1)
xori a1, a1, 30
sra a0, a0, a0
slti a0, a0, -36
lw t2, 0(s1)
sw a1, 0(s1)
lw a1, 0(s1)
srai t2, a1, 16
andi t0, t0, -56
sub t1, a1, t2
mul s0, a1, s0
sub t2, t1, t2
bne s0, a1, skip_25_35
addi t0, s0, 1
skip_25_35: nop
remu a1, s0, s0
sw a1, 0(s1)
lw t2, 0(s1)
sltiu t1, t2, -41
slti t2, t0, 10
sw t2, 0(s1)
add t1, t2, a0
sltiu t0, t2, -28
mv a0, s0
ecall
