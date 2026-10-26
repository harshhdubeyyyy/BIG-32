li t0, 18
li t1, 56
li t2, -5
li a0, -32
li a1, -65
li s0, -53
li s1, 256
sll a0, a1, t0
sltiu a1, s0, 33
and a0, s0, a0
slt t0, t0, t1
lw a1, 0(s1)
or s0, t0, t2
ori s0, a0, -11
div t2, t0, t1
lw a0, 0(s1)
sw t1, 0(s1)
sub t0, a1, t0
slli t1, t1, 5
sltu t0, a1, t0
xori t1, a0, -15
andi t0, s0, -20
lw s0, 0(s1)
div s0, a1, t1
rem a1, t0, t0
srai t1, t1, 2
srai s0, a1, 5
mv a0, s0
ecall
