li t0, 46
li t1, -58
li t2, 61
li a0, -41
li a1, -30
li s0, 22
li s1, 256
lw a1, 0(s1)
bne a1, t2, skip_33_8
addi a1, a1, 1
skip_33_8: nop
bne a0, a0, skip_33_11
addi a1, a0, 1
skip_33_11: nop
xor s0, s0, t0
div a1, a0, t0
ori s0, s0, 17
addi s0, t1, 17
bne t1, t0, skip_33_18
addi t2, t1, 1
skip_33_18: nop
slli t0, s0, 17
xor t2, a1, s0
addi a0, t1, -56
slt s0, s0, s0
sw t0, 0(s1)
srl t2, t0, t0
mul t1, t1, s0
sltu a1, a0, t2
addi t2, a0, 59
rem t2, t0, s0
div a1, s0, a0
div s0, t1, a0
slti t0, s0, 8
ori a0, a1, 56
lw a0, 0(s1)
slli t2, t2, 11
lw t2, 0(s1)
lw t1, 0(s1)
sw s0, 0(s1)
lw a1, 0(s1)
add s0, s0, s0
sub t0, t2, a1
slti t1, t1, -46
srl s0, t0, a1
bne t2, t0, skip_33_45
addi s0, t2, 1
skip_33_45: nop
sw t0, 0(s1)
lw t1, 0(s1)
sw a1, 0(s1)
sub t0, t2, t2
sw t2, 0(s1)
bne t0, t0, skip_33_53
addi s0, t0, 1
skip_33_53: nop
ori t2, a1, -32
mv a0, s0
ecall
