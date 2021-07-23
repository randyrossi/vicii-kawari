!to "field.prg",cbm

; Bytes to enable VICII-Kawari extensions
CHAR_V = 86
CHAR_I = 73
CHAR_C = 67
CHAR_2 = 50

; Some VICII-Kawari registers
KAWARI_VMODE1 = $d037
KAWARI_VMODE2 = $d038
KAWARI_PORT = $d03f

KAWARI_VICSCN = $1000 ; screen ram in KAWARI space

; Kawari video memory port A regs
VMEM_A_IDX = $d035
VMEM_A_HI = $d03a
VMEM_A_LO = $d039
VMEM_A_VAL = $d03b

; Kawari video memory port B regs
VMEM_B_IDX = $d036
VMEM_B_HI = $d03d
VMEM_B_LO = $d03c
VMEM_B_VAL = $d03e

*=$0801

BASIC:  !BYTE $0B,$08,$01,$00,$9E,$32,$30,$36,$33,$00,$00,$00,$00,$00
        ;Adds BASIC line: 1 SYS 2063

init
        ; Enable VICII-Kawari extensions
        lda #CHAR_V
        sta KAWARI_PORT
        lda #CHAR_I
        sta KAWARI_PORT
        lda #CHAR_C
        sta KAWARI_PORT
        lda #CHAR_2
        sta KAWARI_PORT

        ; Turn on hires 320x200 char_pixel_base doesn't matter
        lda #16+64
        sta KAWARI_VMODE1
        ; Bitmap takes entire 32k so vmode2 doesn't matter
        lda #0
        STA KAWARI_VMODE2

        ; now copy from DRAM into VICII-Kawari memory

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
        lda #64     ; color regs start at 64
        sta VMEM_A_LO
        lda #32
        sta KAWARI_PORT  ; make regs visible

        lda #>color
        sta $fc
        ldy #<color
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

wait
        jsr $ffe4
        cmp #0
        beq wait

        lda #0
        sta KAWARI_VMODE1
        lda #32
        sta KAWARI_PORT  ; make regs visible

        ; back to normal colors
        lda #64          ; color regs start at 64
        sta VMEM_A_LO
        lda #>ncolor
        sta $fc
        ldy #<ncolor
        sty $fb
        ldy #0
loop4
        lda ($fb),y
        sta VMEM_A_VAL
        inc VMEM_A_LO
        iny
        tya
        cmp #64
        bne loop4

        lda #0
        sta KAWARI_PORT

        rts

ncolor
!binary "col.bin"

color
!binary "field-col.bin"

bitmap
!binary "field.bin"

