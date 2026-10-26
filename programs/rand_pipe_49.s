li t0, -83
li t1, -12
li t2, 5
li a0, -72
li a1, -18
li a2, 92
li s0, 41
li s1, 256
div t2, t1, a0
lhu a1, 8(s1)
sw a1, 4(s1)
mulhu a2, a1, t2
slti a2, a0, -51
lb a2, 0(s1)
sb a2, 8(s1)
sltu t1, a2, t2
srai a1, a0, 31
div t2, s0, a2
sw t1, 8(s1)
mulh a2, t2, t2
lw a0, 12(s1)
mulh a0, a0, t2
sw t2, 0(s1)
div a0, s0, a0
bne t0, a2, skip_49_16
addi a1, t0, 1
skip_49_16: nop
add t2, a1, a1
lhu t2, 0(s1)
sltu t2, t2, s0
jal ra, sub_49_0
jal ra, sub_49_0
srli t0, s0, 8
rem a0, a1, t0
sh a1, 12(s1)
bne a2, a1, skip_49_25
addi a2, a2, 1
skip_49_25: nop
sra t0, a2, t0
slli s0, s0, 26
div s0, a1, t2
srli s0, s0, 9
or t1, s0, a1
j end_main
sub_49_0:
or s0, a1, t2
or t2, t0, t0
ret
end_main:
mv a0, s0
ecall
