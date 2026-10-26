li t0, 99
li t1, -26
li t2, -79
li a0, -96
li a1, 51
li s0, -22
li s1, 256
or t2, t1, s0
sra t0, t1, a1
lw t0, 0(s1)
sltiu t0, a1, 46
sltu t0, t1, t0
div t1, a1, t1
mul t2, a1, t2
bne t0, a0, skip_23_14
addi a1, t0, 1
skip_23_14: nop
mul a0, a1, a0
ori t1, t1, -14
addi t0, t0, 6
bne a1, t2, skip_23_20
addi t2, a1, 1
skip_23_20: nop
remu t2, a1, t2
slli a1, t1, 6
andi t0, s0, 20
xori s0, a1, -22
srl t0, t0, s0
add t1, t1, s0
bne t0, a1, skip_23_29
addi s0, t0, 1
skip_23_29: nop
bne s0, t0, skip_23_32
addi a0, s0, 1
skip_23_32: nop
add a0, a0, t1
divu a0, a1, t1
lw t2, 0(s1)
div a1, s0, t1
xori t1, t2, -22
lw a0, 0(s1)
lw t1, 0(s1)
sw s0, 0(s1)
srli a1, t2, 19
slli a1, a1, 18
slt s0, t1, t2
srai a0, t1, 5
or s0, a1, t0
mv a0, s0
ecall
