li t0, -73
li t1, 57
li t2, 79
li a0, 93
li a1, 66
li s0, 34
li s1, 256
sub t2, t2, s0
xori t2, a0, 36
srli t0, t2, 22
sw s0, 0(s1)
sltiu t1, a1, 6
sltu s0, t0, t0
rem t0, t2, t1
bne a1, a0, skip_14_14
addi a0, a1, 1
skip_14_14: nop
lw t0, 0(s1)
lw a1, 0(s1)
xori t1, t0, -15
divu a1, t1, a0
rem t2, t0, t0
bne t2, t0, skip_14_22
addi t2, t2, 1
skip_14_22: nop
mul s0, a0, t0
sltiu t0, a0, -21
xori a0, t2, 47
srl t0, t2, a0
sltu a1, a0, t0
sra s0, t2, a1
add s0, a0, a0
xor a1, t2, a0
mul a1, t1, t0
addi t2, t0, -56
slt t0, t0, a1
add t2, t2, t0
bne t0, t1, skip_14_37
addi t1, t0, 1
skip_14_37: nop
mv a0, s0
ecall
