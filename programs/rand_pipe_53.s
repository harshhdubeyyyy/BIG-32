li t0, 57
li t1, -45
li t2, 16
li a0, 28
li a1, 82
li a2, 23
li s0, 83
li s1, 256
rem s0, t0, t1
divu t2, a2, t0
or t1, t2, t1
mul t2, t1, s0
lr.w a1, (s1)
addi a1, a1, 1
sc.w a0, a1, (s1)
jal ra, sub_53_0
srl a2, a1, a0
slli t1, a2, 3
srli s0, a0, 14
csrrw t0, mscratch, t0
csrrs s0, mscratch, zero
lbu s0, 12(s1)
sw s0, 12(s1)
slti s0, t1, 20
lb a2, 12(s1)
bne a2, a0, skip_53_14
addi t1, a2, 1
skip_53_14: nop
lbu t0, 0(s1)
andi t0, t0, 38
xor a0, t0, t1
sra s0, a0, a1
sw s0, 8(s1)
sll t1, s0, a0
divu t0, s0, t0
csrrw t0, mscratch, a2
csrrs a2, mscratch, zero
sw t2, 8(s1)
sb s0, 8(s1)
lhu t1, 8(s1)
srl a2, t1, a1
srai s0, t0, 27
bge a0, t1, skip_53_28
addi a0, a0, 1
skip_53_28: nop
lh t1, 0(s1)
mulhu a0, t1, a1
sll a1, a0, t0
sltu s0, a1, a2
lw a2, 12(s1)
sb a2, 0(s1)
lb a0, 8(s1)
sh a0, 0(s1)
bge t0, a0, skip_53_37
addi a1, t0, 1
skip_53_37: nop
add a2, a1, s0
slti t2, t1, 33
xori a0, t0, -5
lbu s0, 8(s1)
xor a0, s0, a2
slli s0, a2, 28
j end_main
sub_53_0:
sltu t1, t1, a1
sra a2, t1, a1
sll t0, a1, a2
ret
sub_53_1:
and t1, t1, a2
sll t2, t0, t2
sltu t1, t0, s0
ret
end_main:
mv a0, s0
ecall
