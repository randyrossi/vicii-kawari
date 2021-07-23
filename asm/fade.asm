!to "fade.prg",cbm

; Fade foreground and background colors to black
; and then back to the original colors but swapped.
; This assume VICII-Kawari extensions have been enabled

*=$c000

; Some VICII-Kawari registers
KAWARI_PORT = $d03f

VMEM_A_IDX = $d035
VMEM_A_HI = $d03a
VMEM_A_LO = $d039
VMEM_A_VAL = $d03b

EC =$d020
BG =$d021

        lda #32             ; make regs visible
	sta KAWARI_PORT

        lda #0
        sta VMEM_A_IDX
        sta VMEM_A_HI
        sta VMEM_A_LO

        ; Grab current RGB values for EC
        lda EC
        and #15
        tay
        lda #0
mult1
        clc
        adc #4
        dey
        bne mult1

        adc #64 ; color regs start at 64
        sta ec_idx

        sta VMEM_A_LO
        lda VMEM_A_VAL ; red
        sta ec_col
        INC VMEM_A_LO
        lda VMEM_A_VAL ; green
        sta ec_col+1
        INC VMEM_A_LO
        lda VMEM_A_VAL ; blue
        sta ec_col+2
        
        ; Grab current RGB values for BG
        lda BG
        and #15
        tay
        lda #0
mult2
        clc
        adc #4
        dey
        bne mult2

        adc #64 ; color regs start at 64
        sta bg_idx

        sta VMEM_A_LO
        lda VMEM_A_VAL ; red
        sta bg_col
        INC VMEM_A_LO
        lda VMEM_A_VAL ; green
        sta bg_col+1
        INC VMEM_A_LO
        lda VMEM_A_VAL ; blue
        sta bg_col+2

        ; fade both to black
keep_fading:
        ldy ec_idx
	sty VMEM_A_LO
	lda VMEM_A_VAL
        cmp #0
        beq nodec_r
        dec VMEM_A_VAL
nodec_r
        inc VMEM_A_LO
        lda VMEM_A_VAL
	cmp #0
	beq nodec_g
	dec VMEM_A_VAL
nodec_g
        inc VMEM_A_LO
        lda VMEM_A_VAL
	cmp #0
	beq nodec_b
	dec VMEM_A_VAL
nodec_b

        ldy bg_idx
	sty VMEM_A_LO
	lda VMEM_A_VAL
        cmp #0
        beq nodec_r2
        DEC VMEM_A_VAL
nodec_r2
        inc VMEM_A_LO
        lda VMEM_A_VAL
	cmp #0
	beq nodec_g2
	dec VMEM_A_VAL
nodec_g2
        inc VMEM_A_LO
        lda VMEM_A_VAL
	cmp #0
	beq nodec_b2
	dec VMEM_A_VAL
nodec_b2

        ldy #5
delay
        lda #$ff
        cmp $d012
        bne delay
        dey
        bne delay

        ; are they all 0?
        ldy ec_idx
	sty VMEM_A_LO
	lda VMEM_A_VAL
        cmp #0
	bne keep_fading2
	inc VMEM_A_LO
	lda VMEM_A_VAL
        cmp #0
	bne keep_fading2
	inc VMEM_A_LO
	lda VMEM_A_VAL
        cmp #0
	bne keep_fading2
        ldy bg_idx
	sty VMEM_A_LO
	lda VMEM_A_VAL
        cmp #0
	bne keep_fading2
	inc VMEM_A_LO
	lda VMEM_A_VAL
        cmp #0
	bne keep_fading2
	inc VMEM_A_LO
	lda VMEM_A_VAL
        cmp #0
	bne keep_fading2
        jmp fade_done

keep_fading2
	jmp keep_fading

fade_done
                
keep_unfading:
        ldy ec_idx
	sty VMEM_A_LO
	lda VMEM_A_VAL
        cmp bg_col
	bcs reached_r
        inc VMEM_A_VAL
reached_r    
	inc VMEM_A_LO
	lda VMEM_A_VAL
	cmp bg_col+1
	bcs reached_g
	inc VMEM_A_VAL
reached_g
	inc VMEM_A_LO
	lda VMEM_A_VAL
	cmp bg_col+2
	bcs reached_b
	inc VMEM_A_VAL
reached_b

        ldy bg_idx
	sty VMEM_A_LO
	lda VMEM_A_VAL
        cmp ec_col
	bcs reached_r2
        inc VMEM_A_VAL
reached_r2    
	inc VMEM_A_LO
	lda VMEM_A_VAL
	cmp ec_col+1
	bcs reached_g2
	inc VMEM_A_VAL
reached_g2
	inc VMEM_A_LO
	lda VMEM_A_VAL
	cmp ec_col+2
	bcs reached_b2
	inc VMEM_A_VAL
reached_b2

        ldy #5
delay2
        lda #$ff
        cmp $d012
        bne delay2
        dey
        bne delay2

	; all done?
        ldy ec_idx
	sty VMEM_A_LO
	lda VMEM_A_VAL
	cmp bg_col
	bcc keep_unfading2
	inc VMEM_A_LO
	lda VMEM_A_VAL
	cmp bg_col+1
	bcc keep_unfading2
	inc VMEM_A_LO
	lda VMEM_A_VAL
	cmp bg_col+2
	bcc keep_unfading2

        ldy bg_idx
	sty VMEM_A_LO
	lda VMEM_A_VAL
	cmp ec_col
	bcc keep_unfading2
	inc VMEM_A_LO
	lda VMEM_A_VAL
	cmp ec_col+1
	bcc keep_unfading2
	inc VMEM_A_LO
	lda VMEM_A_VAL
	cmp ec_col+2
	bcc keep_unfading2

	rts

keep_unfading2
	jmp keep_unfading

ec_col
        !byte 0,0,0
	
bg_col
        !byte 0,0,0

ec_idx
        !byte 0
bg_idx
        !byte 0
