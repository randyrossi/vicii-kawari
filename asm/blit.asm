!to "blit.prg",cbm

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

wait
        lda $d012
        cmp #200
        bne wait

wait4
        lda $d012
        cmp #200
        beq wait4

        lda #1
        sta $d3ff

wait2
        lda $d012
        cmp #200
        bne wait2

wait3
        lda $d012
        cmp #200
        beq wait3

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
        ; 32 = 001
        ; 64 = 010
        ; 64+32 = 011
        ; 128 = 100
        lda #16+128
        sta KAWARI_VMODE1
        ; Bitmap takes entire 32k so vmode2 doesn't matter
        lda #0
        STA KAWARI_VMODE2

        lda #2
        sta $d020

        lda #$0f    ; DMA
        sta $d03f

        ; SRC
        lda #0      ; width hi
        sta $d02f
        lda #80      ; width lo
        sta $d030

        lda #0      ; height hi
        sta $d031
        lda #100      ; height lo
        sta $d032

        lda #$00      ; src ptr hi
        sta $d035
        lda #$00      ; src ptr lo
        sta $d036

        lda #0      ; src x lo
        sta $d039
        lda #0      ; src x hi
        sta $d03a

        lda #0      ; src y
        sta $d03c

        lda #80    ; src stride
        sta $d03d

        ; set src now
        lda #32
        sta $d03b

        ; dst and op
        lda #8      ; raster op SRC, trans on index 0
        sta $d02f

        lda #$00      ; dst ptr hi
        sta $d035
        lda #$00      ; dst ptr lo
        sta $d036

        lda #80     ; dst x lo
        sta $d039
        lda #0      ; dst x hi
        sta $d03a

        lda #100      ; dst y
        sta $d03c

        lda #80   ; dst stride
        sta $d03d

	; set dst and execute
        lda #64
        sta $d03b

forever:
        jmp forever
