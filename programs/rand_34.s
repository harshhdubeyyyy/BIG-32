li t0, 35
li t1, -9
li t2, 49
li a0, -93
li a1, -42
li s0, -93
li s1, 256
sll t0, a0, t2
xor a1, t1, t0
sub t0, t1, a1
sw s0, 0(s1)
slti t0, a0, 15
sra t2, t1, t1
sltiu a1, t1, 36
addi t1, t1, -45
sw t0, 0(s1)
ori t1, t1, 51
lw t0, 0(s1)
sw a0, 0(s1)
or a0, t2, t1
slt t2, t0, t2
remu a1, t2, a0
divu t2, a1, s0
sub s0, a1, a0
sll t0, t2, a0
sll t1, s0, a0
sltiu s0, t2, 2
addi t0, t1, 3
bne a1, a0, skip_34_28
addi s0, a1, 1
skip_34_28: nop
slli t2, s0, 29
lw s0, 0(s1)
sw a0, 0(s1)
div t1, t1, t2
srai s0, a1, 29
mul a0, a1, a0
srl t1, t0, a0
bne t1, a1, skip_34_38
addi t2, t1, 1
skip_34_38: nop
sltiu t1, a0, 15
divu t2, a1, a1
mv a0, s0
ecall
