li t0, -47
li t1, -98
li t2, 33
li a0, 88
li a1, -91
li s0, -60
li s1, 256
sll s0, t1, s0
sll t2, a0, s0
remu t2, t2, t1
sw t1, 0(s1)
or s0, a1, a0
xori a0, a0, 28
sra t2, s0, s0
or t0, a0, t0
rem t1, a1, s0
slli t2, a1, 6
lw a0, 0(s1)
slti a1, t2, -5
or a1, t2, t0
srl t1, s0, t2
lw t2, 0(s1)
slli t2, a0, 31
sub t0, t2, s0
xor t0, a0, t0
rem a0, a1, a0
bne a1, t0, skip_15_26
addi t0, a1, 1
skip_15_26: nop
andi t0, a1, 50
slti t2, s0, -62
sll s0, a0, a0
sra s0, t2, a1
add t0, a0, a0
lw t2, 0(s1)
lw t0, 0(s1)
mv a0, s0
ecall
