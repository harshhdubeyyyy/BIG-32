li t0, -8
li t1, 20
li t2, 23
li a0, -28
li a1, 6
li s0, -42
li s1, 256
or s0, s0, t2
ori t0, t2, -28
bne t2, t0, skip_16_9
addi a1, t2, 1
skip_16_9: nop
sw t0, 0(s1)
lw a1, 0(s1)
div a0, a1, s0
xor t1, t2, t2
srl t0, t2, a0
slti t1, a1, -53
sll t0, t0, a1
sll t1, t2, t2
xori t0, t1, -61
div a0, t0, a0
sw t0, 0(s1)
andi t0, t1, 39
lw t0, 0(s1)
xori a0, a1, -46
slt t0, s0, t0
add t0, a0, s0
lw t0, 0(s1)
div a0, t1, s0
or t1, a1, t0
andi t0, t0, 4
remu t0, a0, a0
slli a0, t2, 1
srai a0, s0, 24
mul t1, t0, a0
and t0, a0, a0
sw t1, 0(s1)
lw a0, 0(s1)
rem t2, s0, a0
srl a0, t1, s0
sw a1, 0(s1)
div t0, t0, t2
mv a0, s0
ecall
