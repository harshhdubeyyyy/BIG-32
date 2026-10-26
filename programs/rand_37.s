li t0, 74
li t1, 55
li t2, -77
li a0, 58
li a1, 70
li s0, 91
li s1, 256
slti s0, t2, -37
bne a1, t2, skip_37_8
addi a0, a1, 1
skip_37_8: nop
lw s0, 0(s1)
sub t0, t0, a0
xori t2, s0, 29
slti a1, t0, -10
sltiu t0, t0, 28
sll a1, t1, t0
add t1, t0, s0
lw t1, 0(s1)
remu t1, a1, s0
div t0, t2, t2
sltu t1, t1, t2
slti a0, a0, -64
mul t1, t0, a0
and t2, t0, t0
mul t1, s0, a1
add a1, t2, a0
andi a1, t2, -36
slti a0, a1, -62
or t0, a1, t0
slli a0, a0, 12
rem t2, t0, t1
sra a0, a1, s0
add a1, t2, a1
sw t1, 0(s1)
srli t2, s0, 1
divu a0, t1, t2
sw s0, 0(s1)
lw t0, 0(s1)
bne a1, a1, skip_37_39
addi a0, a1, 1
skip_37_39: nop
sltiu t1, s0, -42
and t2, t0, a0
lw s0, 0(s1)
bne a1, t0, skip_37_45
addi a1, a1, 1
skip_37_45: nop
ori t1, t1, -14
and t1, t2, t0
bne t0, t2, skip_37_50
addi a1, t0, 1
skip_37_50: nop
ori t0, t0, -64
bne t2, s0, skip_37_54
addi t1, t2, 1
skip_37_54: nop
mv a0, s0
ecall
