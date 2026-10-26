li t0, 15
li t1, 43
li t2, 99
li a0, 19
li a1, 15
li s0, 30
li s1, 256
sltu a1, a0, s0
sw t2, 0(s1)
add a1, s0, s0
sltiu a0, a0, -24
addi a1, t0, -16
lw a1, 0(s1)
or a1, t1, a1
addi a0, t0, 53
sltiu a0, a1, 1
add t1, a1, t2
rem t0, a0, t0
add t0, t0, s0
div t0, a0, a0
or t0, a1, s0
srli t2, t2, 21
or a0, t0, t1
srli t0, t0, 11
andi t1, a0, -31
srl a0, t0, a0
bne t2, a1, skip_11_26
addi t0, t2, 1
skip_11_26: nop
srl t0, t1, t1
bne s0, a1, skip_11_30
addi a1, s0, 1
skip_11_30: nop
xor t1, t1, a0
srl a1, t2, t2
mul t0, t1, a1
sltu a1, t2, t2
andi a1, a0, 34
rem t1, t2, t1
sltiu s0, t1, -14
addi a0, a0, 43
xor t0, t0, a1
srl s0, a0, t2
sw t2, 0(s1)
andi s0, t0, 58
ori a1, a1, -10
lw t1, 0(s1)
add a0, a0, t1
sltu t2, t2, a1
mv a0, s0
ecall
