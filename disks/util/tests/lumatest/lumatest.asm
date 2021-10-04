!to "lumatest.prg",cbm

  *=$8000

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
        sei; no interrupts

        ; Enable VICII-Kawari extensions
        lda #CHAR_V
        sta KAWARI_PORT
        lda #CHAR_I
        sta KAWARI_PORT
        lda #CHAR_C
        sta KAWARI_PORT
        lda #CHAR_2
        sta KAWARI_PORT

        lda #0
        sta 53280
        sta 53281

        tax
        lda #$20
clrscn: sta $0400,x
        sta $0500,x
        sta $0600,x
        sta $0700,x
        dex
        bne clrscn

        lda #32
        sta KAWARI_PORT

        lda #>sine
        sta $fc
        lda #<sine
        sta $fb

        lda #$a0
        sta VMEM_A_LO

cycle:
        ldy #0
col:
        lda ($fb), y
        sta VMEM_A_VAL
        iny
        jmp col

sine
!byte 63,62,62,62,62,62,62,62,62,62,62,62,61,61,61,61,61,60,60,60,59,59,59,58,58,58,57,57,57,56,56,55,55,54,54,53,53,52,52,51,51,50,50,49,49,48,48,47,46,46,45,45,44,43,43,42,42,41,40,40,39,38,38,37,37,37,36,36,35,34,34,33,32,32,31,31,30,29,29,28,28,27,26,26,25,25,24,24,23,23,22,22,21,21,20,20,19,19,18,18,17,17,17,16,16,16,15,15,15,14,14,14,13,13,13,13,13,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,13,13,13,13,13,14,14,14,15,15,15,16,16,16,17,17,17,18,18,19,19,20,20,21,21,22,22,23,23,24,24,25,25,26,26,27,28,28,29,29,30,31,31,32,32,33,34,34,35,36,36,37,37,37,38,38,39,40,40,41,42,42,43,43,44,45,45,46,46,47,48,48,49,49,50,50,51,51,52,52,53,53,54,54,55,55,56,56,57,57,57,58,58,58,59,59,59,60,60,60,61,61,61,61,61,62,62,62,62,62,62,62,62,62,62,62

