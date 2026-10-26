li t0, -58
li t1, 7
li t2, 76
li a0, 7
li a1, 62
li s0, -28
li s1, 256
sw t1, 0(s1)
ori t1, t0, 45
add t1, t1, s0
sra s0, a0, a1
div t2, a1, a0
div t2, t0, t1
sw a0, 0(s1)
sra s0, t2, a0
rem s0, t0, a0
sw t1, 0(s1)
addi s0, a1, -33
ori a1, a0, -27
lw a0, 0(s1)
bne a0, t2, skip_21_20
addi a1, a0, 1
skip_21_20: nop
bne t2, t0, skip_21_23
addi a0, t2, 1
skip_21_23: nop
sw s0, 0(s1)
bne t0, a0, skip_21_27
addi a0, t0, 1
skip_21_27: nop
or a1, s0, a1
addi t2, a1, -18
ori s0, t2, 14
divu t1, t0, t1
mul t1, s0, t0
andi s0, t1, -61
lw a0, 0(s1)
addi t1, t1, 48
sw t0, 0(s1)
sw s0, 0(s1)
srl a0, t1, t1
and t2, s0, t1
slli a0, t0, 30
remu t1, t2, t1
remu a0, a0, a1
sw a1, 0(s1)
xori t1, s0, -32
bne t2, a1, skip_21_47
addi t0, t2, 1
skip_21_47: nop
mv a0, s0
ecall
