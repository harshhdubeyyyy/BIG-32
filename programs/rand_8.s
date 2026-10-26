li t0, -42
li t1, -6
li t2, -4
li a0, -68
li a1, -51
li s0, 80
li s1, 256
srl t1, a1, t1
xori a0, a0, 62
andi a0, t0, -59
srli a1, a0, 7
slti t0, t0, 32
div t0, t2, t1
sltu s0, a1, t1
sw a1, 0(s1)
bne s0, t1, skip_8_15
addi a0, s0, 1
skip_8_15: nop
sltu a1, a0, s0
lw t2, 0(s1)
sw t1, 0(s1)
srli t0, a1, 22
bne a1, a1, skip_8_22
addi a0, a1, 1
skip_8_22: nop
xor t1, t2, a1
slti t0, a1, -8
or t0, t2, t2
xor a0, t2, a0
sw s0, 0(s1)
or t1, s0, t0
bne t2, t0, skip_8_31
addi t1, t2, 1
skip_8_31: nop
mv a0, s0
ecall
