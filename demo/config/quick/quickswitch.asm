!to "quickswitch.prg",cbm
*=$801

BASIC:  !BYTE $0B,$08,$01,$00,$9E,$32,$30,$36,$33,$00,$00,$00,$00,$00
        ;Adds BASIC line: 1 SYS 2063

KAWARI_PORT = $d03f
VMEM_A_HI = $d03a
VMEM_A_LO = $d039
VMEM_A_VAL = $d03b

; Bytes to enable VICII-Kawari extensions
CHAR_V = 86
CHAR_I = 73
CHAR_C = 67
CHAR_2 = 50

init:
        LDA #CHAR_V
        sta KAWARI_PORT
        LDA #CHAR_I
        sta KAWARI_PORT
        LDA #CHAR_C
        sta KAWARI_PORT
        LDA #CHAR_2
        sta KAWARI_PORT

	; clear screen and print chip
        LDY     #$00
printchip:
        LDA     chiptext,Y
        JSR     $FFD2           ;CHAR OUT
        INY
        CPY     #7
        BNE     printchip

getchip:
	LDA #32
	STA KAWARI_PORT
	LDA #$1f
	STA VMEM_A_LO
	LDA VMEM_A_VAL

	AND #3
	CMP #0
	BEQ chip_6567r8
	CMP #1
	BEQ chip_6569r3
	CMP #2
	BEQ chip_6567r56a
	JMP chip_6569r1

chip_6567r8:
	lda #<txt_6567r8
	sta $fb
	lda #>txt_6567r8
	sta $fc
	jmp printchiptxt

chip_6569r3:
	lda #<txt_6569r3
	sta $fb
	lda #>txt_6569r3
	sta $fc
	jmp printchiptxt

chip_6567r56a:
	lda #<txt_6567r56a
	sta $fb
	lda #>txt_6567r56a
	sta $fc
	jmp printchiptxt

chip_6569r1:
	lda #<txt_6569r1
	sta $fb
	lda #>txt_6569r1
	sta $fc
	jmp printchiptxt

printchiptxt:
        LDY     #$00
printchiptxt2:
        LDA     ($fb),Y
        JSR     $FFD2           ;CHAR OUT
        INY
        CPY     #10
        BNE     printchiptxt2

        LDY     #$00
printmenu:
        LDA     menutext,Y
        JSR     $FFD2           ;CHAR OUT
        INY
        CPY     #48
        BNE     printmenu

	; wait for a key to be pressed
WAITKEY:
	JSR     $FFE4 ; get char
	CMP     #0
	BEQ     WAITKEY

	CMP #49
	BEQ set_6567r8
	CMP #50
	BEQ set_6569r3
	CMP #51
	BEQ set_6567r56a
	CMP #52
	BEQ set_6569r1
	JMP WAITKEY

set_6567r8:
	LDY #0
	JMP set

set_6567r56a:
	LDY #2
	JMP set

set_6569r3:
	LDY #1
	JMP set

set_6569r1:
	LDY #3
	JMP set

set:
	LDA #96 ; persist to registers
	STA KAWARI_PORT
	LDA #$1f
	STA VMEM_A_LO
	STY VMEM_A_VAL
	LDA #0
	STA KAWARI_PORT



        LDY     #$00
printdone:
        LDA     donetext,Y
        JSR     $FFD2           ;CHAR OUT
        INY
        CPY     #5
        BNE     printdone
        RTS


chiptext:
        !BYTE   147,5           ;CLEAR SCREEN AND WHITE
        !PET    "chip:"

txt_6567r8:
        !PET    "6567r8  "
        !BYTE   13,13
txt_6567r56a:
        !PET    "6567r56a"
        !BYTE   13,13
txt_6569r3:
        !PET    "6569r3  "
        !BYTE   13,13
txt_6569r1:
        !PET    "6569r1  "
        !BYTE   13,13

menutext:
        !PET    "1. 6567r8  "
        !BYTE   13
        !PET    "2. 6567r56a"
        !BYTE   13
        !PET    "3. 6569r3  "
        !BYTE   13
        !PET    "4. 6569r1  "
        !BYTE   13

seltext:
        !PET    "select:"

donetext:
        !PET    "done"
        !BYTE   13
