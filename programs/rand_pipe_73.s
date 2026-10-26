li t0, -29
li t1, -69
li t2, 28
li a0, 22
li a1, 44
li a2, -54
li s0, 18
li s1, 256
or a0, a1, a1
slli t0, t2, 26
xori a0, a0, -18
lr.w t2, (s1)
addi t2, t2, 1
sc.w a1, t2, (s1)
sra a2, a1, t0
divu t2, t2, t1
xor s0, t2, s0
bne t0, s0, skip_73_7
addi a2, t0, 1
skip_73_7: nop
sw t0, 0(s1)
lb t1, 12(s1)
srai s0, t1, 15
xori t2, t1, -37
amoadd.w a0, t0, (s1)
lb t0, 8(s1)
divu t0, t0, t1
bge a1, t2, skip_73_15
addi s0, a1, 1
skip_73_15: nop
xori a2, a0, -56
rem t0, t0, a2
sw a2, 8(s1)
xor t0, t0, a2
srl a2, t0, t1
sltu a2, a2, s0
andi a2, a2, -60
jal ra, sub_73_0
jal ra, sub_73_1
amoadd.w t0, a1, (s1)
andi a1, a0, 12
remu t2, t1, a0
srli t1, a0, 4
sltu a2, t1, t0
sb a2, 8(s1)
sb s0, 12(s1)
lw a0, 0(s1)
sub a1, a0, a2
sra t1, a1, t2
sw t0, 12(s1)
ori s0, a0, -64
lr.w t2, (s1)
addi t2, t2, 1
sc.w a2, t2, (s1)
mul a2, a2, s0
srli s0, a2, 10
div a1, t0, s0
remu a1, t0, a1
sub t0, a1, a0
sw s0, 4(s1)
andi a1, s0, -11
srl a2, a1, a1
or s0, a2, a2
divu a0, a0, t2
j end_main
sub_73_0:
mul a1, t0, t0
and t1, t1, t0
sll a2, t1, a2
sub t1, t2, s0
ret
sub_73_1:
and s0, t1, a2
slt a1, a2, t2
srl t0, a1, t1
ret
end_main:
mv a0, s0
ecall
