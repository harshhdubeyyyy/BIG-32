li t0, -83
li t1, -12
li t2, 5
li a0, -72
li a1, -18
li s0, 92
li s1, 256
sltiu t0, s0, 6
slt s0, t0, s0
ori a1, t2, 38
srl s0, t1, t0
srai t2, t2, 25
bne a1, t0, skip_49_12
addi a1, a1, 1
skip_49_12: nop
andi s0, a1, -48
ori a1, a1, -30
slti t1, t2, 47
bne s0, s0, skip_49_18
addi a0, s0, 1
skip_49_18: nop
slti a0, t2, -59
addi t1, t0, 13
div s0, s0, t2
xori a0, t2, -15
slli t2, s0, 16
srl t0, t0, s0
sltiu a0, s0, -46
ori t1, t1, -62
slti t2, t2, -35
sub t2, a1, a0
mul t2, s0, s0
bne t1, a0, skip_49_32
addi s0, t1, 1
skip_49_32: nop
andi a1, a0, 32
ori t2, a1, 16
bne s0, a1, skip_49_37
addi s0, s0, 1
skip_49_37: nop
addi a1, s0, -7
xor t0, a0, a0
bne t0, a0, skip_49_42
addi a1, t0, 1
skip_49_42: nop
srli a1, t2, 14
sw a1, 0(s1)
bne a0, t1, skip_49_47
addi t2, a0, 1
skip_49_47: nop
rem a1, t1, t1
add t2, t2, t1
sub t0, s0, t0
lw a1, 0(s1)
xori t2, t2, 48
addi t2, t2, 13
mv a0, s0
ecall
