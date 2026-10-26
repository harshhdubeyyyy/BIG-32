li t0, 21
li t1, -32
li t2, 68
li a0, 35
li a1, 70
li s0, -11
li s1, 256
mul t2, a0, t2
sw t1, 0(s1)
xori s0, a1, 30
rem t1, t0, a1
mul a1, s0, t2
rem t0, t0, t0
lw a1, 0(s1)
bne a0, t0, skip_12_14
addi a0, a0, 1
skip_12_14: nop
slti t1, a1, -23
bne a1, t1, skip_12_18
addi t0, a1, 1
skip_12_18: nop
xori t0, a0, 56
sltiu a0, a1, -43
bne t2, t2, skip_12_23
addi s0, t2, 1
skip_12_23: nop
bne a0, s0, skip_12_26
addi s0, a0, 1
skip_12_26: nop
sll t2, t1, t2
add a1, a1, t1
add a0, t0, a1
or a0, t0, a0
slli t0, a1, 4
xori t0, a0, 24
xori s0, t0, 30
div t2, a0, a0
bne t1, t1, skip_12_37
addi a0, t1, 1
skip_12_37: nop
andi a1, t2, -8
mv a0, s0
ecall
