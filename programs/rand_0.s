li t0, -2
li t1, 94
li t2, 7
li a0, -90
li a1, -34
li s0, 30
li s1, 256
sltu t2, a0, t2
lw t1, 0(s1)
remu t0, a1, t2
ori s0, a1, -39
srai s0, t2, 6
remu t2, a1, s0
rem a1, a0, a0
addi t0, a1, 38
srai s0, s0, 31
sw s0, 0(s1)
or t0, t1, a1
sub t1, a1, a0
sub t2, a1, a0
slt t2, s0, t0
slt a1, t1, a1
xori a0, t0, 17
andi t2, t1, -56
addi s0, t2, -42
addi t1, t1, 36
sw a1, 0(s1)
sw a1, 0(s1)
sw t2, 0(s1)
ori s0, s0, -43
mul t0, a0, a1
div t1, t1, t0
divu s0, t1, t2
divu a0, t0, t0
rem s0, t1, t0
addi a1, a1, -58
sub t1, a1, a1
sltu t2, t0, t0
sra t1, s0, t0
slt t0, s0, t0
or t0, t2, t0
and t2, t2, a0
mv a0, s0
ecall
