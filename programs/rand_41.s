li t0, -3
li t1, -15
li t2, -41
li a0, -58
li a1, -2
li s0, 47
li s1, 256
addi a0, s0, -1
andi t0, a0, 17
sltu s0, s0, a1
rem a1, t0, a0
div s0, t1, t0
mul a0, t1, a1
remu t0, t1, s0
bne t2, t2, skip_41_14
addi t0, t2, 1
skip_41_14: nop
and t0, a1, a1
and t0, t2, a0
mul t0, a0, t0
addi a0, t1, -30
slt s0, a0, a0
srai a1, t0, 29
add t1, t0, s0
srai s0, t0, 8
lw a0, 0(s1)
srai a1, a1, 6
bne t1, a0, skip_41_27
addi t1, t1, 1
skip_41_27: nop
srl a0, s0, s0
sw t2, 0(s1)
xori s0, t1, 19
sw t2, 0(s1)
srai s0, t0, 10
mul t1, t1, a0
sltu t1, a1, a1
srl t2, t0, t1
sltiu t0, a0, -15
ori a0, a0, 26
mv a0, s0
ecall
