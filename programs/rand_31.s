li t0, -97
li t1, 20
li t2, -72
li a0, 95
li a1, 0
li s0, -64
li s1, 256
div t0, a1, t1
srai t1, s0, 3
slt a1, s0, a0
add a1, t0, t0
slli a0, t2, 21
div a1, t1, t1
add a1, s0, a1
bne t2, t1, skip_31_14
addi t1, t2, 1
skip_31_14: nop
div a0, t0, t0
andi a0, s0, 46
slli t1, t2, 30
sltu t2, t2, t2
or s0, s0, t2
bne t2, t1, skip_31_22
addi t0, t2, 1
skip_31_22: nop
addi a1, s0, -20
sub a1, t2, s0
andi t2, t2, -35
addi t2, a0, -34
or s0, t0, t1
add s0, t1, a0
slti a1, t2, 61
mv a0, s0
ecall
