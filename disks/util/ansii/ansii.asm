!to "ansii.prg",cbm

; Some VICII-Kawari registers
KAWARI_VMODE1 = $d037
KAWARI_VMODE2 = $d038
KAWARI_PORT = $d03f

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

CHAR_V = 86
CHAR_I = 73
CHAR_C = 67
CHAR_2 = 50

*=$801

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

install_colors:
        lda #0
        sta VMEM_A_HI
        lda #64     ; color regs start at 64
        sta VMEM_A_LO
        lda #32
        sta KAWARI_PORT  ; make regs visible, no inc

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

        lda #$a0     ; luma
        sta VMEM_A_LO
loop4
        lda ($fb),y
        sta VMEM_A_VAL
        inc VMEM_A_LO
        iny
        tya
        cmp #80
        bne loop4

        lda #$b0     ; phase
        sta VMEM_A_LO
loop5
        lda ($fb),y
        sta VMEM_A_VAL
        inc VMEM_A_LO
        iny
        tya
        cmp #96
        bne loop5

        lda #$c0     ; amp
        sta VMEM_A_LO
loop6
        lda ($fb),y
        sta VMEM_A_VAL
        inc VMEM_A_LO
        iny
        tya
        cmp #112
        bne loop6

	rts

color
; red,green,blue values for ANSII colors
!byte 0,0,0,0,51,0,0,0,19,38,1,0,49,40,0,0,28,39,51,0,29,20,30,0,1,38,38,0,52,53,51,0,21,21,20,0,59,10,10,0,34,56,13,0,63,58,19,0,12,43,63,0,43,31,42,0,13,56,56,0,63,63,63,0

; luma, phase, amplitude values for ANSII colors
!byte 12,50,38,48,51,30,38,53,21,59,55,62,63,42,55,63,0,79,144,114,229,30,208,0,0,79,144,117,224,41,208,0,0,15,14,15,6,5,14,0,0,12,11,10,12,3,11,0

