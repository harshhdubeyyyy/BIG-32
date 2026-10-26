li t0, 4
li t1, 33
li t2, 38
li a0, 79
li a1, -71
li s0, -55
li s1, 256
sltu t0, t1, t0
xor t1, a1, s0
sltiu a0, a1, 19
and t2, t2, a1
xor t0, a1, t0
bne s0, t2, skip_44_12
addi t0, s0, 1
skip_44_12: nop
sra a0, t0, a0
lw t1, 0(s1)
srai t0, t0, 27
srai s0, s0, 21
sltu a0, s0, a0
sw a0, 0(s1)
slti s0, s0, -53
sltu t0, t1, t0
srli s0, a1, 22
ori a0, t0, -36
sw t0, 0(s1)
bne s0, a1, skip_44_26
addi t0, s0, 1
skip_44_26: nop
sltiu t1, t1, -63
ori t2, s0, -45
slt t2, t1, s0
xori t1, t0, 3
bne a1, t2, skip_44_33
addi a1, a1, 1
skip_44_33: nop
xori a0, t0, 12
sub t2, a1, a0
and t1, t1, s0
sll a0, a0, s0
lw t0, 0(s1)
srai t2, s0, 23
sra s0, t1, a1
and t2, a0, s0
bne t2, t1, skip_44_44
addi a0, t2, 1
skip_44_44: nop
mv a0, s0
ecall
