li t0, 63
li t1, 7
li t2, 9
li a0, 93
li a1, 85
li s0, -74
li s1, 256
sltu a0, t2, t0
ori a1, t2, 20
xori t2, a0, -7
lw t0, 0(s1)
srl a1, t1, t0
slt a1, s0, a1
sub a0, t0, t2
srli a0, t0, 18
xori t2, a0, 9
sltiu t1, a0, -23
sltiu t0, t1, -1
remu t0, t1, a0
lw t2, 0(s1)
lw a1, 0(s1)
lw a1, 0(s1)
sub s0, a0, s0
sra a1, t0, a1
sw t1, 0(s1)
lw a1, 0(s1)
srai t1, t0, 16
sltiu t0, t0, -11
add t1, a0, t1
mv a0, s0
ecall
