li t0, -66
li t1, 45
li t2, 95
li a0, -84
li a1, -35
li s0, -70
li s1, 256
slli a0, s0, 6
addi a0, a0, 50
remu t1, a1, t0
slt t0, t0, s0
srl a0, s0, t1
srli a1, t1, 14
xor s0, t1, a0
lw a0, 0(s1)
sub s0, s0, t2
srli s0, s0, 12
srl a1, a0, a1
sltiu t0, a0, 39
remu t1, t2, a1
slli s0, s0, 28
xori t0, t1, 30
ori t0, a0, 36
addi t1, a1, -13
slti a1, t1, 24
bne t2, a0, skip_1_25
addi a1, t2, 1
skip_1_25: nop
lw s0, 0(s1)
bne a0, s0, skip_1_29
addi t0, a0, 1
skip_1_29: nop
andi t1, a1, 45
bne t2, a1, skip_1_33
addi a0, t2, 1
skip_1_33: nop
ori a1, a0, 42
divu a1, a1, a1
andi a0, a1, -19
ori t1, t0, -56
sw t0, 0(s1)
lw a0, 0(s1)
sll t0, a1, t1
slt t1, t1, t2
bne t2, s0, skip_1_44
addi s0, t2, 1
skip_1_44: nop
srli a0, s0, 30
srl t2, a0, t2
sw t2, 0(s1)
mv a0, s0
ecall
