!to "segment2.prg",cbm

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

*=$40ad

init

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

next_command:
        ; load command byte
        ldy #0
        lda ($fb),y

        beq install_colors       

        tax
        and #128
        beq streak
        jmp bytes

advance:
        inc $fb
        bne advance2
        inc $fc
advance2:
        rts

; bit 8 is on so this is a group of bytes
bytes:
        txa
        and #127
        tax
l1:
        jsr advance
        lda ($fb),y
        sta VMEM_A_VAL
        dex
        bne l1
        jsr advance
        jmp next_command

streak:
        jsr advance
        lda ($fb),y
l2:
        sta VMEM_A_VAL
        dex
        bne l2
        jsr advance
        jmp next_command

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

        ; Something is hitting $d03f unexpectedly later on
        ; and if we leave VMEM_A_LO pointing to 0x80, it will
        ; kill the blanking level and composite will be garbage
        ; So set it to somthing harmless. TODO: Find this
        lda #0
        sta VMEM_A_LO
        lda #0
        sta KAWARI_PORT

        ; Turn on hires 320x200 char_pixel_base doesn't matter
        lda #16+64
        sta KAWARI_VMODE1
        ; Bitmap takes entire 32k so vmode2 doesn't matter
        lda #0
        STA KAWARI_VMODE2
        ; Leave image showing

;wait
;        jsr $ffe4
;        cmp #0
;        beq wait

        rts

color
!binary "kawariinsidergb.bin"
!binary "kawariinsidehsv.bin"

bitmap
!binary "kawariinside_compressed.bin"

