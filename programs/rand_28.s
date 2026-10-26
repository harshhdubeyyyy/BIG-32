li t0, -72
li t1, 90
li t2, -67
li a0, 39
li a1, 52
li s0, 82
li s1, 256
or s0, a0, a0
sltu a0, t1, t1
sub t0, a0, t1
and t2, s0, t1
lw a1, 0(s1)
srai t2, a1, 28
mul t0, t2, s0
div a1, a1, t2
sll a0, t1, t1
and a0, a0, t2
mul t2, a0, a1
slti t1, t1, -16
slli a1, a0, 12
div t2, t2, s0
slli a0, t0, 31
xori a1, a0, -24
xori t1, a0, -5
srl t0, t0, a0
sltiu t2, a0, -64
ori a0, t2, -43
sltu t1, a1, t0
rem s0, s0, t2
andi s0, a0, -15
slt a1, t0, a0
divu a1, a0, s0
mv a0, s0
ecall
