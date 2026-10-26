li t0, 46
li t1, -92
li t2, 9
li a0, 23
li a1, 47
li s0, -97
li s1, 256
andi a0, t2, -56
sltiu t2, t0, 28
srl t1, a1, t2
and s0, t2, a0
xori s0, t2, -3
bne a0, t0, skip_10_12
addi a1, a0, 1
skip_10_12: nop
ori t1, t1, 29
srai t1, t2, 28
sll t0, s0, a1
sw a0, 0(s1)
rem t0, a0, t2
andi t0, a1, 34
addi t2, a1, -40
srl t1, t2, a0
sltu s0, t2, t1
ori t0, t2, -22
ori t1, t1, 19
add t0, a1, s0
xor t2, t1, t0
remu a1, t1, a0
lw s0, 0(s1)
slti t2, a1, 63
remu a0, s0, a0
sll a0, a1, a1
slti a0, s0, 48
sra a0, t0, t0
mv a0, s0
ecall
