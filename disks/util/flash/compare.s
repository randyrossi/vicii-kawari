KAWARI_VMODE1 = $d037
KAWARI_VMODE2 = $d038
KAWARI_PORT = $d03f
VMEM_A_IDX = $d035
VMEM_A_HI = $d03a
VMEM_A_LO = $d039
VMEM_A_VAL = $d03b
VMEM_B_IDX = $d036
VMEM_B_HI = $d03d
VMEM_B_LO = $d03c
VMEM_B_VAL = $d03e

; compares vmem starting at 0x0000 to dram memory
; fb/fc = lo/hi of mem address to compare to
; fd/fe = lo/hi byte of size of block
; sets fd to 0 for equal blocks, 1 otherwise
_compare:
        lda #0
        sta VMEM_A_IDX

        ; auto inc port a
        lda #1
        sta KAWARI_PORT
        
	; start at 0x0000
        lda #0
	sta VMEM_A_HI
        lda #0
	sta VMEM_A_LO

	ldy #0
iter:
        ; Expect data at $6000
	lda VMEM_A_HI
	adc #$60
	sta $fc
	lda VMEM_A_LO
	sta $fb

	lda VMEM_A_VAL
	cmp ($fb),y
	bne fail

	lda VMEM_A_HI
	CMP $fe
	bne iter
	lda VMEM_A_LO
	cmp $fd
	bne iter

stop:
        lda #0
        sta KAWARI_PORT
	sta $fd
	rts

fail:
        lda #0
        sta KAWARI_PORT
	lda #1
	sta $fd
	rts
	
.export _compare
