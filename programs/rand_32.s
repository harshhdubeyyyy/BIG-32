li t0, -81
li t1, -46
li t2, -63
li a0, -23
li a1, 78
li s0, -40
li s1, 256
slt t0, t0, t2
remu t0, a1, s0
andi a1, t0, -62
xori t1, t2, -44
div t0, a1, t0
remu t0, a0, t0
sra t2, t1, t1
rem a0, t1, a1
sw a1, 0(s1)
andi t0, a1, 9
rem t1, s0, a0
bne s0, t0, skip_32_18
addi a0, s0, 1
skip_32_18: nop
sw a0, 0(s1)
mul t0, t0, t1
srl a1, t2, t1
add a1, t0, a0
ori a1, s0, 61
slti t1, a1, -5
sll a0, a1, s0
mul a1, t1, a1
sw t1, 0(s1)
addi t0, a0, -64
andi t1, t2, 52
sll t2, a0, t1
and s0, a1, t1
sw a0, 0(s1)
addi t2, a0, -18
lw t0, 0(s1)
or a1, t2, a0
and t2, t1, s0
mul a0, t0, a0
lw t0, 0(s1)
sub t0, t1, t2
srai t0, a1, 21
slli t0, t2, 14
mv a0, s0
ecall
