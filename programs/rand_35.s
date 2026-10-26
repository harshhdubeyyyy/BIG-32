li t0, 40
li t1, -15
li t2, 92
li a0, -67
li a1, 91
li s0, -13
li s1, 256
div t2, a1, t0
sltiu t2, s0, -40
div a1, t0, t0
sltiu s0, t0, 63
and t1, t2, t0
rem a1, t0, a0
sub t2, t1, a1
xori t1, a1, 62
xor a1, a0, t0
slli a0, a1, 7
addi a1, a0, 32
mul t1, a0, a0
or a1, s0, t1
sw s0, 0(s1)
add t0, s0, t1
add a0, a1, a1
ori a1, t1, 49
srai t0, s0, 17
xori t1, t2, 10
slti s0, t0, -43
sltiu t2, s0, 33
sub a1, s0, a0
and t2, s0, a1
bne t1, s0, skip_35_30
addi t0, t1, 1
skip_35_30: nop
mv a0, s0
ecall
