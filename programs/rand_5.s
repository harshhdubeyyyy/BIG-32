li t0, 59
li t1, -35
li t2, 89
li a0, -9
li a1, 76
li s0, 89
li s1, 256
lw t0, 0(s1)
xori t1, t0, -1
add t0, a1, t1
srli a0, t2, 10
srai t0, t1, 28
divu t0, t0, t1
sll t1, t1, t2
bne s0, s0, skip_5_14
addi a1, s0, 1
skip_5_14: nop
xor s0, t1, a0
xor a0, t1, t1
add t2, a1, a1
ori s0, t2, 26
sw t2, 0(s1)
add a0, s0, t1
rem t0, s0, t2
srl a1, a0, t2
sltiu t0, a0, -18
xori t1, t0, 24
addi a1, t2, 30
sw t0, 0(s1)
remu a1, a1, t2
sub t2, s0, a1
divu t2, t2, t1
xor t1, s0, s0
bne s0, t0, skip_5_33
addi t1, s0, 1
skip_5_33: nop
add a1, a1, a0
sra a1, t2, t2
addi t1, t0, 62
sltu t1, t1, s0
bne a0, t0, skip_5_40
addi s0, a0, 1
skip_5_40: nop
rem t2, t1, t0
rem t1, a0, a1
div a1, a0, a0
srli a0, t2, 25
lw t0, 0(s1)
bne a0, t2, skip_5_48
addi s0, a0, 1
skip_5_48: nop
divu a0, t2, a1
ori a1, t2, -56
srai t2, a1, 17
sw s0, 0(s1)
mv a0, s0
ecall
