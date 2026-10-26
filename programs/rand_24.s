li t0, 82
li t1, -2
li t2, 49
li a0, -54
li a1, -45
li s0, -58
li s1, 256
divu s0, t0, s0
bne t2, s0, skip_24_8
addi s0, t2, 1
skip_24_8: nop
lw t0, 0(s1)
lw s0, 0(s1)
sltiu a0, s0, 13
slti t0, s0, -24
sltiu t2, t0, 29
ori t0, t1, -47
divu t1, s0, a1
slt a0, t2, t2
srli t1, t0, 9
sltiu t2, a0, -31
slti t2, a1, -2
mul t1, t2, t2
ori t1, a0, 39
divu t2, t2, t2
rem a1, a0, t2
lw t2, 0(s1)
lw s0, 0(s1)
sll t0, t0, t0
srai a0, a1, 26
sw t2, 0(s1)
remu t1, t2, s0
remu a1, s0, t0
mul a1, t0, s0
xor s0, a0, t2
mv a0, s0
ecall
