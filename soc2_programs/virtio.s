# Virtio-mmio block test (M-mode, bare, on soc2). a0 = fail count.
# Virtio base 0x10001000. Queue: desc 0x80020000, avail
# 0x80021000, used 0x80022000, QueueNum 8. Header buffer
# 0x80023000, data buffer 0x80024000, status byte 0x80025000.
# Scratch result words at 0x8000F000 (checked by the driver).
start:
    li sp, 0x80010000
    li s0, 0
    li t0, 0x10001000
    # Identify: magic, version, device id, capacity.
    lw t1, 0(t0)
    li t2, 0x74726976
    bne t1, t2, fail
    lw t1, 4(t0)
    li t2, 2
    bne t1, t2, fail
    lw t1, 8(t0)
    li t2, 2
    bne t1, t2, fail
    lw t1, 0x100(t0)
    li t2, 2048
    bne t1, t2, fail
    # Reset, then ACK | DRIVER | FEATURES_OK.
    sw x0, 0x70(t0)
    li t1, 1
    sw t1, 0x70(t0)
    li t1, 3
    sw t1, 0x70(t0)
    lw t1, 0x10(t0)    # features (expect 0)
    bne t1, x0, fail
    sw x0, 0x20(t0)    # driver features = 0
    li t1, 0xB
    sw t1, 0x70(t0)
    # Queue addresses and number, then READY, then DRIVER_OK.
    li t1, 0x80020000
    sw t1, 0x80(t0)    # desc lo
    sw x0, 0x84(t0)    # desc hi
    li t1, 0x80021000
    sw t1, 0x90(t0)    # avail lo
    sw x0, 0x94(t0)
    li t1, 0x80022000
    sw t1, 0xA0(t0)    # used lo
    sw x0, 0xA4(t0)
    li t1, 8
    sw t1, 0x38(t0)    # QueueNum
    li t1, 1
    sw t1, 0x44(t0)    # QueueReady
    li t1, 0xF
    sw t1, 0x70(t0)    # DRIVER_OK
    # ---- READ sector 5 into 0x80024000 ----
    jal ra, build_read5
    jal ra, notify_wait
    # Status byte must be 0, used idx 1, len 512, data word
    # 0x05050505 (sector 5 pattern byte = 5).
    li t0, 0x80025000
    lbu t1, 0(t0)
    bne t1, x0, fail
    li t0, 0x80022000
    lhu t1, 2(t0)      # used idx
    li t2, 1
    bne t1, t2, fail
    lw t1, 8(t0)       # used entry len (entry at +4: id, len)
    li t2, 512
    bne t1, t2, fail
    li t0, 0x80024000
    lw t1, 0(t0)
    li t2, 0x05050505
    bne t1, t2, fail
    # Ack the interrupt, check InterruptStatus clears.
    li t0, 0x10001000
    li t1, 1
    sw t1, 0x64(t0)    # InterruptACK
    lw t1, 0x60(t0)
    bne t1, x0, fail
    # ---- WRITE sector 6 (pattern 0xAABBCCDD), then READ back ----
    jal ra, build_write6
    jal ra, notify_wait
    li t0, 0x80025000
    lbu t1, 0(t0)
    bne t1, x0, fail
    jal ra, build_read6
    jal ra, notify_wait
    li t0, 0x80025000
    lbu t1, 0(t0)
    bne t1, x0, fail
    li t0, 0x80024000
    lw t1, 0(t0)
    li t2, 0xAABBCCDD
    bne t1, t2, fail
    j done
fail:
    addi s0, s0, 1
done:
    mv a0, s0
    ecall

# Build a READ chain for sector 5. Clobbers t0-t2, a0-a1.
build_read5:
    li t0, 0x80023000
    sw x0, 0(t0)       # type = 0 (read)
    sw x0, 4(t0)       # reserved
    li t1, 5
    sw t1, 8(t0)       # sector lo
    sw x0, 12(t0)      # sector hi
    li t0, 0x80020000
    li t1, 0x80023000
    sw t1, 0(t0)       # desc0 addr
    sw x0, 4(t0)
    li t1, 16
    sw t1, 8(t0)       # desc0 len
    li t1, 0x10001      # flags NEXT | next=1
    sw t1, 12(t0)
    li t1, 0x80024000
    sw t1, 16(t0)      # desc1 addr
    sw x0, 20(t0)
    li t1, 512
    sw t1, 24(t0)      # desc1 len
    li t1, 0x20002      # flags WRITE | next=2
    sw t1, 28(t0)
    li t1, 0x80025000
    sw t1, 32(t0)      # desc2 addr
    sw x0, 36(t0)
    li t1, 1
    sw t1, 40(t0)      # desc2 len
    li t1, 0x2         # flags WRITE, no NEXT
    sw t1, 44(t0)
    li t0, 0x80021000
    sw x0, 0(t0)       # avail flags
    li t1, 1
    sh t1, 2(t0)       # avail idx = 1
    sh x0, 4(t0)       # avail ring[0] = 0
    ret

# Build a WRITE chain for sector 6 from buffer 0x80024000,
# first filling the buffer with 0xAABBCCDD words.
build_write6:
    li t0, 0x80024000
    li t1, 0xAABBCCDD
    li t2, 128
fill6:
    sw t1, 0(t0)
    addi t0, t0, 4
    addi t2, t2, -1
    bne t2, x0, fill6
    li t0, 0x80023000
    li t1, 1
    sw t1, 0(t0)       # type = 1 (write)
    sw x0, 4(t0)
    li t1, 6
    sw t1, 8(t0)       # sector lo
    sw x0, 12(t0)
    li t0, 0x80020000
    li t1, 0x80023000
    sw t1, 0(t0)
    sw x0, 4(t0)
    li t1, 16
    sw t1, 8(t0)
    li t1, 0x10001
    sw t1, 12(t0)
    li t1, 0x80024000
    sw t1, 16(t0)
    sw x0, 20(t0)
    li t1, 512
    sw t1, 24(t0)
    li t1, 0x2         # flags 0, next=2 (no WRITE: device reads)
    sw t1, 28(t0)
    # NOTE: flags word encoding is (next<<16)|flags; for desc1
    # here flags=0, next=2 -> 0x20000. Corrected below.
    li t1, 0x20000
    sw t1, 28(t0)
    li t1, 0x80025000
    sw t1, 32(t0)
    sw x0, 36(t0)
    li t1, 1
    sw t1, 40(t0)
    li t1, 0x2
    sw t1, 44(t0)
    li t0, 0x80021000
    li t1, 2
    sh t1, 2(t0)       # avail idx = 2
    sh x0, 4(t0)       # avail ring[0] reused (idx 2 -> entry 1?)
    # Avail ring has 2 entries used so far; the device reads
    # ring[avail_idx % QueueNum] via its own idx tracking:
    # it reads the CURRENT avail idx from the ring word, so
    # ring[1] must hold desc 0. Write ring[1] = 0.
    sh x0, 6(t0)
    ret

# Build a READ chain for sector 6 (into 0x80024000).
build_read6:
    li t0, 0x80023000
    sw x0, 0(t0)
    sw x0, 4(t0)
    li t1, 6
    sw t1, 8(t0)
    sw x0, 12(t0)
    li t0, 0x80020000
    li t1, 0x80023000
    sw t1, 0(t0)
    sw x0, 4(t0)
    li t1, 16
    sw t1, 8(t0)
    li t1, 0x10001
    sw t1, 12(t0)
    li t1, 0x80024000
    sw t1, 16(t0)
    sw x0, 20(t0)
    li t1, 512
    sw t1, 24(t0)
    li t1, 0x20002
    sw t1, 28(t0)
    li t1, 0x80025000
    sw t1, 32(t0)
    sw x0, 36(t0)
    li t1, 1
    sw t1, 40(t0)
    li t1, 0x2
    sw t1, 44(t0)
    li t0, 0x80021000
    li t1, 3
    sh t1, 2(t0)       # avail idx = 3
    sh x0, 4(t0)       # ring[0]
    sh x0, 6(t0)       # ring[1]
    sh x0, 8(t0)       # ring[2] = 0
    ret

# Notify queue 0, then poll InterruptStatus bit 0 (timeout).
notify_wait:
    li t0, 0x10001000
    sw x0, 0x50(t0)    # QueueNotify = 0
    li t1, 100000
poll_v:
    lw t2, 0x60(t0)    # InterruptStatus
    andi t2, t2, 1
    bne t2, x0, notified
    addi t1, t1, -1
    bne t1, x0, poll_v
    # Timeout: count as failure in the caller? Signal via s0.
    addi s0, s0, 1
notified:
    ret
