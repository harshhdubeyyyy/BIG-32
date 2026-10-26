li t0, 46
li t1, -80
li t2, 24
li a0, 95
li a1, -34
li s0, -91
li s1, 256
sll a1, a0, s0
divu t0, t2, a0
mul a0, a1, a1
divu a1, a1, s0
slli s0, a1, 27
divu t0, t2, a0
div s0, t0, t1
slti t2, t0, -13
sw t1, 0(s1)
addi s0, s0, 28
sltu a0, t2, t2
or a1, s0, a1
div s0, t2, t2
sltu a0, t1, t1
or s0, a1, t0
srai t0, s0, 19
and a1, a0, t2
xori a0, t0, 37
remu a0, t1, t0
addi a0, a0, 45
mv a0, s0
ecall
