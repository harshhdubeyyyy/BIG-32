li t0, 40
li t1, -81
li t2, -12
li a0, 53
li a1, 55
li s0, -27
li s1, 256
addi t2, a0, -56
divu a0, s0, t1
slt a0, t2, a1
and s0, t1, a0
sltu a0, s0, s0
ori a1, s0, 7
slti t1, a0, -28
srai t2, a1, 30
remu a1, t0, s0
div t1, t2, t1
and t0, a1, a0
xor s0, a0, a0
lw s0, 0(s1)
srai s0, s0, 13
xori t0, t0, -30
div t2, t0, t0
add s0, t2, t0
bne t0, t0, skip_29_24
addi a1, t0, 1
skip_29_24: nop
sltiu t0, t1, 50
or t0, t0, s0
sub t0, t1, t1
slli t0, s0, 12
mv a0, s0
ecall
