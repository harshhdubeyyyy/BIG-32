li t0, 85
li t1, 75
li t2, 96
li a0, -62
li a1, -34
li s0, 72
li s1, 256
sw a1, 0(s1)
lw t0, 0(s1)
bne t1, t2, skip_20_9
addi t0, t1, 1
skip_20_9: nop
andi a1, a0, -13
srl s0, t2, t2
sub a1, a0, a0
sub t1, t0, t1
xor t2, s0, t2
addi t1, a1, 4
slli t1, a1, 0
sw t2, 0(s1)
div s0, t2, a1
slt t1, s0, t2
sw a0, 0(s1)
lw t0, 0(s1)
bne a0, t2, skip_20_24
addi a1, a0, 1
skip_20_24: nop
or a1, t0, a1
divu t1, t0, t0
lw t0, 0(s1)
sltiu a0, a0, -51
sw a0, 0(s1)
sltiu t0, t0, -37
mul t2, s0, t0
sw t0, 0(s1)
add a1, a1, s0
remu s0, s0, a1
xor t2, t1, a0
or t0, t1, t1
sw t1, 0(s1)
xori t1, s0, 60
srl t1, s0, t2
bne t2, t1, skip_20_42
addi t0, t2, 1
skip_20_42: nop
div t2, t1, s0
sll t2, t0, a0
slli t2, a0, 4
sltiu t1, t0, -47
lw a1, 0(s1)
srai t1, t2, 6
or t0, t1, s0
addi a0, s0, 28
mv a0, s0
ecall
