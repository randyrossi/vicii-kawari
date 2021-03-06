!to "ball.prg",cbm

!source "kawari.inc"

*=$0801

BASIC:  !BYTE $0B,$08,$01,$00,$9E,$32,$30,$36,$33,$00,$00,$00,$00,$00
        ;Adds BASIC line: 1 SYS 2063

init
        jmp main

!source "kawari-util.inc"

main
        ; Make border/background color 0
        lda #0
        sta 53280
        sta 53281

        jsr activate_kawari

        ; Turn on hires 320x200
        lda #16+64
        sta KAWARI_VMODE1
        ; Bitmap takes 32k in bank 0
        lda #0
        STA KAWARI_VMODE2

        ; now copy the bitmap from DRAM into VICII-Kawari memory

        lda #>bitmap
        sta $fc
        lda #<bitmap
        sta $fb

        lda #$00    ; we're going to copy it to video ram $0000
        sta VMEM_A_IDX
        sta VMEM_A_HI
        sta VMEM_A_LO
        lda #1      ; use auto increment
        sta KAWARI_PORT

        ldy #0
        ; copy bitmap loop
        ldx #$80    ; we loop 128 times (128x256 = 32Kb)
loop2   lda ($fb),y ; read byte from src $fb/$fc
        sta VMEM_A_VAL   ; write byte to dest video ram
        iny         ; do this 256 times...
        bne loop2   ; ..for low byte $00 to $FF
        inc $fc     ; when we passed $FF increase high byte...
        dex         ; ... and decrease X by one before restart
        bne loop2   ; We repeat this until X becomes Zero

        lda #0
        sta VMEM_A_HI
        lda #32
        sta KAWARI_PORT  ; make regs visible

        jsr save_colors

        ; install new colors
        lda #64     ; color regs start at 64
        sta VMEM_A_LO

        lda #>rgb_color
        sta $fc
        ldy #<rgb_color
        sty $fb
        ldy #0
loop3
        lda ($fb),y
        sta VMEM_A_VAL
        inc VMEM_A_LO
        iny
        tya
        cmp #64
        bne loop3

        lda #$a0     ; hsv regs start at a0
        sta VMEM_A_LO

        lda #>hsv_color
        sta $fc
        ldy #<hsv_color
        sty $fb
        ldy #0
loop4
        lda ($fb),y
        sta VMEM_A_VAL
        inc VMEM_A_LO
        iny
        tya
        cmp #48
        bne loop4


        ; wait for raster line 255
wait
        jsr $ffe4
        cmp #0
        bne exit

        lda $d012
	cmp #255
        bne wait

        jmp docolmov1

exit
        jsr restore_colors

        lda #0
        sta KAWARI_VMODE1
        rts

        ; cycle the HSV colors
docolmov1
	ldy #14
        lda #$a1
        sta VMEM_A_LO
        lda #$a2
        sta VMEM_B_LO
        lda VMEM_A_VAL
        tax
colmov1
        lda VMEM_B_VAL
        sta VMEM_A_VAL
        inc VMEM_A_LO
        inc VMEM_B_LO
	dey
	bne colmov1
        lda #$af
	sta VMEM_A_LO
	stx VMEM_A_VAL
        
docolmov2
	ldy #14
        lda #$b1
        sta VMEM_A_LO
        lda #$b2
        sta VMEM_B_LO
        lda VMEM_A_VAL
        tax
colmov2
        lda VMEM_B_VAL
        sta VMEM_A_VAL
        inc VMEM_A_LO
        inc VMEM_B_LO
	dey
	bne colmov2
        lda #$bf
	sta VMEM_A_LO
	stx VMEM_A_VAL

docolmov3
	ldy #14
        lda #$c1
        sta VMEM_A_LO
        lda #$c2
        sta VMEM_B_LO
        lda VMEM_A_VAL
        tax
colmov3
        lda VMEM_B_VAL
        sta VMEM_A_VAL
        inc VMEM_A_LO
        inc VMEM_B_LO
	dey
	bne colmov3
        lda #$cf
	sta VMEM_A_LO
	stx VMEM_A_VAL

        ; cycle the RGB colors but do it the opposite
        ; way just to mess with people who might have
        ; both displays hooked up

        ; remember last RGB
        lda #124
        STA VMEM_A_LO
        LDA VMEM_A_VAL
	STA tmpr
	INC VMEM_A_LO
        LDA VMEM_A_VAL
	STA tmpg
	INC VMEM_A_LO
        LDA VMEM_A_VAL
	STA tmpb

        ; setup for move
        lda #124
        STA VMEM_A_LO
        lda #120
        STA VMEM_B_LO

        ldy #14
rgb1
        lda VMEM_B_VAL ; R
        sta VMEM_A_VAL ; R
        inc VMEM_A_LO
        inc VMEM_B_LO
        lda VMEM_B_VAL ; G
        sta VMEM_A_VAL ; G
        inc VMEM_A_LO
        inc VMEM_B_LO
        lda VMEM_B_VAL ; B
        sta VMEM_A_VAL ; B

        ; r/g/b moved, now sub 6 from ptrs
        dec VMEM_A_LO
        dec VMEM_A_LO
        dec VMEM_A_LO
        dec VMEM_A_LO
        dec VMEM_A_LO
        dec VMEM_A_LO
        dec VMEM_B_LO
        dec VMEM_B_LO
        dec VMEM_B_LO
        dec VMEM_B_LO
        dec VMEM_B_LO
        dec VMEM_B_LO

        dey
        bne rgb1

        ; now put what was in last pos to 1st
        lda #68
        STA VMEM_A_LO
        LDA tmpr
	STA VMEM_A_VAL
	INC VMEM_A_LO
        LDA tmpg
	STA VMEM_A_VAL
	INC VMEM_A_LO
        LDA tmpb
	STA VMEM_A_VAL

        jmp wait


rgb_color
!byte   0,0,0,0    ; does not get cycled
!byte   63,0,0,0
!byte   63,0,0,0
!byte   63,0,0,0
!byte   63,0,0,0
!byte   63,0,0,0
!byte   63,0,0,0
!byte   63,0,0,0
!byte   63,0,0,0
!byte   63,63,63,0
!byte   63,63,63,0
!byte   63,63,63,0
!byte   63,63,63,0
!byte   63,63,63,0
!byte   63,63,63,0
!byte   63,63,63,0

hsv_color
!byte   12,24,24,24,24,24,24,24,24,63,63,63,63,63,63,63
!byte   0,80,80,80,80,80,80,80,80,0,0,0,0,0,0,0
!byte   0,5,5,5,5,5,5,5,5,0,0,0,0,0,0,0

tmpr
!byte 0
tmpg
!byte 0
tmpb
!byte 0

bitmap
!binary "ball.bin"

