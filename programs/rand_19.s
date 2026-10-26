li t0, 73
li t1, -89
li t2, 100
li a0, 33
li a1, -70
li s0, 30
li s1, 256
and a1, t2, a1
ori t0, t2, 4
sw t0, 0(s1)
addi t1, t0, 52
srl s0, t0, t0
divu a1, s0, a0
sw t2, 0(s1)
xori a1, t1, -5
slli a1, s0, 24
sub t1, s0, a0
xori a0, t0, -34
xori a1, a0, -18
lw t1, 0(s1)
sltiu a0, t0, 3
lw a0, 0(s1)
sra s0, t1, a0
or s0, t0, t0
sub a0, t0, a0
andi a0, s0, 47
andi t0, t0, 46
sltu a0, t0, t1
sltiu s0, t0, -25
xor a0, a1, s0
bne a1, a1, skip_19_30
addi t0, a1, 1
skip_19_30: nop
slti t2, t1, 17
sub t2, s0, t1
mv a0, s0
ecall
