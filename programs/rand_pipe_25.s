li t0, -4
li t1, 96
li t2, -97
li a0, -46
li a1, -22
li a2, 62
li s0, 21
li s1, 256
sltu a1, a0, t0
lr.w a1, (s1)
addi a1, a1, 1
sc.w a2, a1, (s1)
lr.w a1, (s1)
addi a1, a1, 1
sc.w a1, a1, (s1)
slti t1, a1, 56
sw a2, 8(s1)
slti t1, a2, 53
slt a0, t1, t0
lb a2, 0(s1)
amoadd.w t1, s0, (s1)
srli a1, a0, 30
srli s0, s0, 10
srl a0, s0, s0
lb a0, 12(s1)
lb t2, 0(s1)
mul a2, t2, t1
rem t1, t1, s0
mulhu a2, t1, a1
sh t2, 12(s1)
sh a0, 12(s1)
ori t0, s0, 42
slti t0, a2, -6
sh a1, 0(s1)
div t2, a1, s0
add s0, t2, a2
sub t1, s0, t2
mul a2, t1, a2
sub t2, a2, t2
jal ra, sub_25_0
jal ra, sub_25_0
mulh a1, t0, t2
sub s0, a1, t2
div a2, t0, t2
srli t2, s0, 18
xor t0, t2, t1
lr.w t0, (s1)
addi t0, t0, 1
sc.w t2, t0, (s1)
sltu t2, t2, a2
jal ra, sub_25_0
sw a1, 8(s1)
j end_main
sub_25_0:
xor t2, s0, t1
srl t2, t0, t1
mul t0, t0, t1
ret
end_main:
mv a0, s0
ecall
