!to "hires80.prg",cbm

; bytes to enable VICII-Kawari extensions
CHAR_V = 86
CHAR_I = 73
CHAR_C = 67
CHAR_2 = 50

; some VICII-Kawari registers
KAWARI_VMODE1 = $d037
KAWARI_VMODE2 = $d038
KAWARI_PORT = $d03f

KAWARI_VICSCN = $1000 ; screen ram hi bytes, takes the place of $0400

VMEM_A_IDX = $d035
VMEM_A_HI = $d03a
VMEM_A_LO = $d039
VMEM_A_VAL = $d03b

VMEM_B_IDX = $d036
VMEM_B_HI = $d03d
VMEM_B_LO = $d03c
VMEM_B_VAL = $d03e

R6510  = $01
NWRAP  = $02
DFLTN  = $99   ; Default Input Device (0)
DFLTO  = $9A   ; Default Output (CMD) Device (3)
SAL    = $AC
SAH    = $AD
EAL    = $AE
EAH    = $AF
NDX    = $C6   ; No. of Chars. in Keyboard Buffer (Queue)
RVS    = $C7   ; Flag: Print Reverse Chars. -1=Yes, 0=No Used
LXSP   = $C9   ; Cursor X-Y Pos. at Start of INPUT
LSXP   = $C9   ; Cursor X-Y Pos. at Start of INPUT
LSTP   = $CA   ;
INDX   = $C8   ; Pointer: End of Logical Line for INPUT
BLNSW  = $CC   ; Cursor Blink enable: 0 = Flash Cursor
GDBLN  = $CE   ; Character Under Cursor
BLNON  = $CF   ; Flag: Last Cursor Blink On/Off
BLNCT  = $CD   ; Timer: Countdown to Toggle Cursor
CRSW   = $D0   ; Flag: INPUT or GET from Keyboard
PNT    = $D1   ; Pointer: Current Screen Line Address
PNTR   = $D3   ; Cursor Column on Current Line
QTSW   = $D4   ; Flag: Editor in Quote Mode, $00 = NO
LNMX   = $D5   ; Physical Screen Line Length
TBLX   = $D6   ; Current Cursor Physical Line Number
DATA   = $D7   ; Temp Data Area
INSRT  = $D8   ; Flag: Insert Mode, >0 = # INSTs
LDTB1  = $D9
USER   = $F3   ; Pointer: Current Screen Color RAM loc.
KEYD   = $0277 ; Keyboard Buffer Queue (FIFO)
COLOR  = $0286 ; Current Character Color Code
GDCOL  = $0287 ; Background Color Under Cursor
SHFLAG = $028D ; Flag: Keyb'rd SHIFT Key/CTRL Key/C= Key
MODE   = $0291 ; Flag: $00=Disable SHIFT Keys, $80 = Enable SHIFT Keys
AUTODN = $0292 ; Auto Down
LINTMP = $02a5
CINV   = $0314
IBASIN = $0324
IBSOUT = $0326
USRCMD = $032E
HIBASE = $0288

CPATCH = $E4DA
LP2    = $E5B4
LOWER  = $EC44
UPPER  = $EC4F
RUNTB  = $ECE7

; LDTB2=$ECF0         ; replaced by our new table
COLM   =$DC00
ROWS   =$DC01
VICCOL =$1800          ; replaces $d800 ; !!! NEED ANOTHER LOC FOR THIS

ORIG_BASOUT = $F1D5
ORIG_BASIN  = $F173

MAXCHR = 80             ;80 COLUMNS ON A LINE
NLINES = 25             ;25 ROWS ON SCREEN
LLEN   = 80             ;80 COLUMNS ON SCREEN

*=$c800

        ; Enable VICII-Kawari extensions
	lda #CHAR_V
        sta KAWARI_PORT
	lda #CHAR_I
        sta KAWARI_PORT
	lda #CHAR_C
        sta KAWARI_PORT
	lda #CHAR_2
        sta KAWARI_PORT

	LDA #0
	STA VMEM_A_IDX
	STA VMEM_B_IDX

	; We need to first copy char rom from $d000 into
	; $c000, then turn off ROM and copy from $c000 into
	; Kawari video memory.

	; first $d000 to $c000

        sei         ; disable interrupts while we copy 
        ldx #$10    ; we loop 16 times (16x256 = 4Kb)
        lda #$33    ; make the CPU see the Character Generator ROM...
        sta $01     ; ...at $D000 by storing %00110011 into location $01
        lda #$d0    ; load high byte of $D000
        sta $fc     ; store it in a free location we use as vector
        ldy #$00    ; init counter with 0
        sty $fb     ; store it as low byte in the $FB/$FC vector

        lda #$90    ; we're going to copy it to $9000
        sta $fe
        lda #$00
        sta $fd

loop    lda ($fb),y ; read byte from src $fb/$fc
        sta ($fd),y ; write byte to dest $fd/$fe
        iny         ; do this 255 times...
        bne loop    ; ..for low byte $00 to $FF
        inc $fc     ; when we passed $FF increase high byte...
        inc $fe     ; when we passed $FF increase high byte...
        dex         ; ... and decrease X by one before restart
        bne loop    ; We repeat this until X becomes Zero

        lda #$37    ; switch in I/O mapped registers again...
        sta $01     ; ... with %00110111 so CPU can see them

        ; now copy from $c000 into VICII-Kawari memory

        lda #$90    ; load high byte of $9000
        sta $fc     ; store it in a free location we use as vector
        ldy #$00    ; init counter with 0
        sty $fb     ; store it as low byte in the $FB/$FC vector

        lda #$00    ; we're going to copy it to video ram $0000
        sta VMEM_A_HI
        lda #$00
        sta VMEM_A_LO
        lda #1      ; use auto increment
	sta KAWARI_PORT

        ; copy loop
        ldx #$10    ; we loop 16 times (16x256 = 4Kb)
loop2   lda ($fb),y ; read byte from src $fb/$fc
        sta VMEM_A_VAL   ; write byte to dest video ram
        iny         ; do this 256 times...
        bne loop2   ; ..for low byte $00 to $FF
        inc $fc     ; when we passed $FF increase high byte...
        dex         ; ... and decrease X by one before restart
        bne loop2   ; We repeat this until X becomes Zero

        ; clear 2k video matrix memory starting @ 0x1000 with spaces
        ldx #8      ; loop 8 times (8x256 = 2Kb)
	ldy #0
        lda #$10    ; set address
        sta VMEM_A_HI
        lda #$00
        sta VMEM_A_LO
	lda #$20    ; space character
loop3   sta VMEM_A_VAL
	iny
	bne loop3
        dex
        bne loop3

        ; clear 2k color memory starting @ 0x1800

        ldx #8      ; loop 8 times (8x256 = 2Kb)
	ldy #0
        lda #$18    ; set address
        sta VMEM_A_HI
        lda #$00
        sta VMEM_A_LO
	lda #$e      ; light blue
loop4   sta VMEM_A_VAL
	iny
	bne loop4
        dex
        bne loop4

        ; set new cinv routine
	lda #<new_cinv
	sta CINV
	lda #>new_cinv
	sta CINV + 1

        ; set new bsin routine
        lda #<new_bsin
	sta IBASIN
	lda #>new_bsin
	sta IBASIN + 1

        ; set new bsout routine
        lda #<new_bsout
	sta IBSOUT
	lda #>new_bsout
	sta IBSOUT + 1

        ; our high byte for the screen is $10
	lda #$10
	sta HIBASE

        ; finally, turn on hires mode
	; char rom is at $0000 (4k)
	; screen ram is at $1000 (2k)
	; color ram is at $1800 (2k)
        lda #16            ; uuu:h:p:cp  uuu:1:0:000 $0000
	sta KAWARI_VMODE1
        lda #50            ; col:mat = 0011:0010 $1800:$1000
	sta KAWARI_VMODE2
	LDA #0             ; no inc
	STA KAWARI_PORT

        cli         ; turn off interrupt disable flag

        jmp ($A000) ; BASIC cold start

new_bsout:
	sta DATA          ; save char data
	pha
	lda DFLTO         ; get device number
	cmp #3
	bne oldbso        ; not screen? do old bsout
	txa
	pha
	tya
	pha
	lda DATA
	jsr bsout_core
	pla
	tay
	pla
	tax
	pla
	clc
	cli ; XXX user may have wanted interrupts off!
	rts
oldbso:	jmp ORIG_BASOUT ; original non-screen BSOUT

; CLSR was e544
CLSR
	LDA HIBASE ;FILL HI BYTE PTR TABLE
        ORA #$80
        TAY
        LDA #0
        TAX
LPS1    STY LDTB1,X
        CLC
        ADC #LLEN
        BCC LPS2
        INY             ;CARRY BUMP HI BYTE
LPS2    INX
        CPX #NLINES+1   ;DONE # OF LINES?
        BNE LPS1        ;NO...
        LDA #$FF        ;TAG END OF LINE TABLE
        STA LDTB1,X
        LDX #NLINES-1   ;CLEAR FROM THE BOTTOM LINE UP
CLEAR1  JSR CLRLN       ;SEE SCROLL ROUTINES
        DEX
        BPL CLEAR1

;NXTD HOME FUNCTION was E566

NXTD   
       LDY #0
       STY    PNTR            ;LEFT COLUMN
       STY    TBLX            ;TOP LINE

                              ;MOVE CURSOR TO TBLX,PNTR

; STUPT was e56c
STUPT
       LDX TBLX        ;GET CURENT LINE INDEX
       LDA PNTR        ;GET CHARACTER POINTER
FNDSTR
       LDY LDTB1,X     ;FIND BEGINING OF LINE
       BMI STOK        ;BRANCH IF START FOUND
       CLC
       ADC #LLEN       ;ADJUST POINTER
       STA PNTR
       DEX
       BPL FNDSTR

STOK
       JSR SETPNT      ;SET UP PNT INDIRECT 901227-03**********
 
       LDA #LLEN-1
       INX
FNDEND
       LDY LDTB1,X
       BMI STDONE
       CLC
       ADC #LLEN
       INX
       BPL FNDEND
STDONE
       STA LNMX
       JMP SCOLOR      ;MAKE COLOR POINTER FOLLOW 901227-03**********
                       ; THIS IS A PATCH FOR INPUT LOGIC 901227-03**********
                       ;   FIXES INPUT"XXXXXXX-40-XXXXX";A$ PROBLEM
                       ;
FINPUT
       CPX LSXP        ;CHECK IF ON SAME LINE
       BEQ FINPUX      ;YES..RETURN TO SEND
       JMP FINDST      ;CHECK IF WE WRAPPED DOWN...
FINPUX
       RTS

new_bsin:
	LDA DFLTN       ;CHECK DEVICE
	BNE    BN10            ;IS NOT KEYBOARD...
	LDA    PNTR            ;SAVE CURRENT...
	STA    LSTP            ;... CURSOR COLUMN
	LDA    TBLX            ;SAVE CURRENT...
	STA    LSXP            ;... LINE NUMBER
	JMP    LOOP5           ;BLINK CURSOR UNTIL RETURN
BN10
	CMP    #3              ; IS INPUT FROM SCREEN?
        BNE    BN20            ; NO

        STA CRSW               ;FAKE A CARRIAGE RETURN
        LDA LNMX               ; SAY WE ENDED...
        STA INDX               ;... UP ON THIS LINE
        JMP    LOOP5           ;PICK UP CHARACTERS
BN20
	JMP    ORIG_BASIN      ;Continue to original basin

; Originally at $e5ca
; LOOP4 is a helper func for main bsin_core
; routine which was originally at $e632
LOOP4
	JSR PRT
LOOP3
	LDA    NDX
	STA    BLNSW
	STA    AUTODN          ;TURN ON AUTO SCROLL DOWN
	BEQ    LOOP3
	SEI
	LDA    BLNON
	BEQ    LP21
	LDA    GDBLN
	LDX    GDCOL           ;RESTORE ORIGINAL COLOR
	LDY    #0
	STY    BLNON
	JSR    DSPP
LP21  
	JSR LP2
	CMP    #$83            ;RUN KEY?
       BNE LP22
       LDX #9
       SEI
       STX NDX
LP23  
	LDA RUNTB-1,X
       STA KEYD-1,X
       DEX
       BNE LP23
       BEQ LOOP3
LP22  
	CMP #$D
	BNE    LOOP4
	LDY    LNMX
	STY    CRSW

	JSR PNT_TO_VMEM_A
CLP5
	;LDA (PNT),Y
	STY VMEM_A_IDX 
	LDA VMEM_A_VAL

	CMP    #$20
	BNE    CLP6
	DEY
	BNE    CLP5
CLP6  
	INY
	STY    INDX
	LDY    #0
       STY AUTODN      ;TURN OFF AUTO SCROLL DOWN
	STY    PNTR
	STY    QTSW
	LDA    LSXP
	BMI    LOP5
       LDX TBLX
       JSR FINDST      ;FIND 1ST PHYSICAL LINE
       CPX LSXP
	BNE    LOP5
	LDA    LSTP
	STA    PNTR
	CMP    INDX
	BCC    LOP5
	BCS    CLP2

;INPUT A LINE UNTIL CARRIAGE RETURN

bsin_core
LOOP5 
	TYA
	PHA
	TXA
	PHA
	LDA    CRSW
	BEQ    LOOP3

	JSR PNT_TO_VMEM_A
LOP5  
	LDY PNTR
	;LDA    (PNT),Y
	STY VMEM_A_IDX
	LDA VMEM_A_VAL
NOTONE
	STA    DATA
LOP51 
	AND #$3F
	ASL    DATA
	BIT    DATA
	BPL    LOP54
	ORA    #$80
LOP54 
	BCC LOP52
	LDX    QTSW
	BNE    LOP53
LOP52 
	BVS LOP53
	ORA    #$40
LOP53 
	INC PNTR
	JSR    QTSWC
	CPY    INDX
	BNE    CLP1
CLP2  
	LDA #0
	STA    CRSW
	LDA    #$D
	LDX    DFLTN           ;FIX GETS FROM SCREEN
	CPX    #3              ;IS IT THE SCREEN?
	BEQ    CLP2A
	LDX    DFLTO
	CPX    #3
	BEQ    CLP21
CLP2A 
	JSR PRT
CLP21 
	LDA #$D
CLP1  
	STA DATA
	PLA
	TAX
	PLA
	TAY
	LDA    DATA
	CMP    #$DE            ;IS IT <PI> ?
	BNE    CLP7
	LDA    #$FF
CLP7  
	CLC
	RTS
QTSWC 
	CMP #$22
	BNE    QTSWL
	LDA    QTSW
	EOR    #$1
	STA    QTSW
	LDA    #$22
QTSWL 
	RTS
NXT33 
	ORA #$40
NXT3  
	LDX RVS
	BEQ    NVS
NC3   
	ORA #$80
NVS   
	LDX INSRT
	BEQ    NVS1
	DEC    INSRT
NVS1  
	LDX COLOR ; PUT COLOR ON SCREEN
	JSR    DSPP
       JSR WLOGIC      ;CHECK FOR WRAPAROUND
LOOP2 
	PLA
	TAY
	LDA    INSRT
	BEQ    LOP2
	LSR    QTSW
LOP2   PLA
	TAX
	PLA
	CLC                    ;GOOD RETURN
	CLI
	RTS
WLOGIC
       JSR CHKDWN      ;MAYBE WE SHOULD WE INCREMENT TBLX
       INC PNTR        ;BUMP CHARCTER POINTER
       LDA LNMX        ;
       CMP PNTR        ;IF LNMX IS LESS THAN PNTR
       BCS WLGRTS      ;BRANCH IF LNMX>=PNTR
       CMP #MAXCHR-1   ;PAST MAX CHARACTERS
       BEQ WLOG10      ;BRANCH IF SO
       LDA AUTODN      ;SHOULD WE AUTO SCROLL DOWN?
       BEQ WLOG20      ;BRANCH IF NOT
	JMP    BMT1            ;ELSE DECIDE WHICH WAY TO SCROLL
WLOG20
       LDX TBLX        ;SEE IF WE SHOULD SCROLL DOWN
       CPX #NLINES
       BCC WLOG30      ;BRANCH IF NOT
       JSR SCROL       ;ELSE DO THE SCROL UP
       DEC TBLX        ;AND ADJUST CURENT LINE#
       LDX TBLX
WLOG30
	ASL LDTB1,X     ;WRAP THE LINE
       LSR LDTB1,X
       INX             ;INDEX TO NEXT LLINE
       LDA LDTB1,X     ;GET HIGH ORDER BYTE OF ADDRESS
       ORA #$80        ;MAKE IT A NON-CONTINUATION LINE
       STA LDTB1,X     ;AND PUT IT BACK
       DEX             ;GET BACK TO CURRENT LINE
       LDA LNMX        ;CONTINUE THE BYTES TAKEN OUT
       CLC
       ADC #LLEN
       STA LNMX
FINDST
       LDA LDTB1,X     ;IS THIS THE FIRST LINE?
       BMI FINX        ;BRANCH IF SO
       DEX             ;ELSE BACKUP 1
       BNE FINDST
FINX
       JMP SETPNT      ;MAKE SURE PNT IS RIGHT
WLOG10
	DEC TBLX
       JSR NXLN
       LDA #0
       STA PNTR        ;POINT TO FIRST BYTE
WLGRTS
	RTS
BKLN  
	LDX TBLX
       BNE BKLN1
       STX PNTR
       PLA
       PLA
       BNE LOOP2
;
BKLN1 
	DEX
       STX TBLX
       JSR STUPT
       LDY LNMX
       STY PNTR
       RTS

; Originally found found @ $e716
bsout_core
PRT   
	PHA
	STA    DATA
	TXA
	PHA
	TYA
	PHA
	LDA    #0
	STA    CRSW
	LDY    PNTR
	LDA    DATA
	BPL    *+5
	JMP    NXTX
	CMP    #$D
	BNE    NJT1
	JMP    NXT1
NJT1   
	CMP #$20
	BCC    NTCN
	CMP    #$60            ;LOWER CASE?
	BCC    NJT8            ;NO...
	AND    #$DF            ;YES...MAKE SCREEN LOWER
	BNE    NJT9            ;ALWAYS
NJT8   
	AND #$3F
NJT9   
	JSR QTSWC
	JMP    NXT3
NTCN   
	LDX INSRT
	BEQ    CNC3X
	JMP    NC3
CNC3X  
	CMP #$14
	BNE    NTCN1
	TYA
	BNE    BAK1UP
	JSR BKLN
	JMP BK2
BAK1UP        
	JSR CHKBAK      ;SHOULD WE DEC TBLX
	       DEY
	STY    PNTR
BK1   
	JSR SCOLOR      ;FIX COLOR PTRS

	JSR PNT_TO_VMEM_A
	JSR USER_TO_VMEM_B
BK15  
	INY
	;LDA    (PNT),Y
	STY VMEM_A_IDX
	LDA VMEM_A_VAL
	DEY
	;STA    (PNT),Y
	STY VMEM_A_IDX
	STA VMEM_A_VAL
	INY
	;LDA    (USER),Y
	STY VMEM_B_IDX
	LDA VMEM_B_VAL
	DEY
	;STA    (USER),Y
	STY VMEM_B_IDX
	STA VMEM_B_VAL
	INY
	CPY    LNMX
	BNE    BK15
BK2   
	JSR PNT_TO_VMEM_A
	JSR USER_TO_VMEM_B

	LDA #$20
	;STA    (PNT),Y
	STY VMEM_A_IDX
	STA VMEM_A_VAL
	LDA    COLOR
	;STA    (USER),Y
	STY VMEM_B_IDX
	STA VMEM_B_VAL
	BPL    JPL3
NTCN1  
	LDX QTSW
	BEQ    NC3W
CNC3  
	JMP NC3
NC3W   
	CMP #$12
	BNE    NC1
	STA    RVS
NC1    
	CMP #$13
	BNE    NC2
	JSR    NXTD
NC2   
	CMP #$1D
	BNE    NCX2
	INY
	       JSR CHKDWN
	STY    PNTR
	DEY
	CPY    LNMX
	BCC    NCZ2
	       DEC TBLX
	JSR    NXLN
	LDY    #0
JPL4  
	STY PNTR
NCZ2   
	JMP LOOP2
NCX2   
	CMP #$11
	BNE    COLR1
	CLC
	TYA
	ADC    #LLEN
	TAY
	       INC TBLX
	CMP    LNMX
	BCC    JPL4
	BEQ    JPL4
	       DEC TBLX
CURS10 
	SBC #LLEN
	       BCC GOTDWN
	       STA PNTR
	       BNE CURS10
GOTDWN 
	JSR NXLN
JPL3  
	JMP LOOP2
COLR1  
	JSR CHKCOL      ;CHECK FOR A COLOR
	       JMP LOWER       ;WAS JMP LOOP2
	;CHECK COLOR
	;
	;SHIFTED KEYS
	;
NXTX
KEEPIT
	AND    #$7F
	CMP    #$7F
	BNE    NXTX1
	LDA    #$5E
NXTX1
NXTXA
	       CMP #$20        ;IS IT A FUNCTION KEY
	BCC    UHUH
	JMP    NXT33
UHUH
	CMP    #$D
	BNE    UP5
	JMP    NXT1
UP5   
	LDX  QTSW
	BNE    UP6
	CMP    #$14
	BNE    UP9
	LDY    LNMX
	JSR PNT_TO_VMEM_A
	;LDA    (PNT),Y
	STY VMEM_A_IDX
	LDA VMEM_A_VAL
	CMP    #$20
	BNE    INS3
	CPY    PNTR
	BNE    INS1
INS3   
	CPY #MAXCHR-1
	BEQ    INSEXT          ;EXIT IF LINE TOO LONG
	JSR    NEWLIN          ;SCROLL DOWN 1
INS1   
	LDY LNMX
	JSR    SCOLOR
	JSR PNT_TO_VMEM_A
	JSR USER_TO_VMEM_B
INS2   
	DEY
	;LDA    (PNT),Y
	STY VMEM_A_IDX
	LDA VMEM_A_VAL
	INY
	;STA    (PNT),Y
	STY VMEM_A_IDX
	STA VMEM_A_VAL
	DEY
	;LDA    (USER),Y
	STY VMEM_B_IDX
	LDA VMEM_B_VAL
	INY
	;STA    (USER),Y
	STY VMEM_B_IDX
	STA VMEM_B_VAL
	DEY
	CPY    PNTR
	BNE    INS2
	LDA    #$20
	;STA    (PNT),Y
	STY VMEM_A_IDX
	STA VMEM_A_VAL
	LDA    COLOR
	;STA    (USER),Y
	STY VMEM_B_IDX
	STA VMEM_B_VAL
	INC    INSRT
INSEXT 
	JMP LOOP2
UP9    
	LDX INSRT
	BEQ    UP2
UP6    
	ORA #$40
	JMP    NC3
UP2    
	CMP #$11
	BNE    NXT2
	LDX    TBLX
	       BEQ JPL2
	       DEC TBLX
	       LDA PNTR
	       SEC
	       SBC #LLEN
	       BCC UPALIN
	       STA PNTR
	       BPL JPL2
UPALIN 
	JSR STUPT
	BNE    JPL2
NXT2   
	CMP #$12
	BNE    NXT6
	LDA    #0
	STA    RVS
NXT6   
	CMP #$1D
	BNE    NXT61
	       TYA
	BEQ    BAKBAK
	JSR    CHKBAK
	DEY
	STY    PNTR
	       JMP LOOP2
BAKBAK 
	JSR BKLN
	JMP    LOOP2
NXT61  
	CMP #$13
	BNE    SCCL
	JSR    CLSR
JPL2   
	JMP LOOP2
SCCL
	ORA    #$80            ;MAKE IT UPPER CASE
	JSR    CHKCOL          ;TRY FOR COLOR
	       JMP UPPER       ;WAS JMP LOOP2
	;
NXLN   
	LSR LSXP
	LDX    TBLX
NXLN2  
	INX
	CPX    #NLINES         ;OFF BOTTOM?
	BNE    NXLN1           ;NO...
	JSR    SCROL           ;YES...SCROLL
NXLN1  
	LDA LDTB1,X     ;DOUBLE LINE?
	BPL    NXLN2           ;YES...SCROLL AGAIN
	STX    TBLX
	JMP    STUPT
NXT1
	LDX    #0
	STX    INSRT
	STX    RVS
	STX    QTSW
	STX    PNTR
	JSR    NXLN
JPL5   
	JMP LOOP2
	;
	;
	; CHECK FOR A DECREMENT TBLX
	;
CHKBAK 
	LDX #NWRAP
	       LDA #0
CHKLUP 
	CMP PNTR
	       BEQ BACK
	       CLC
	       ADC #LLEN
	       DEX
	       BNE CHKLUP
	       RTS
	;
BACK   
	DEC TBLX
	       RTS
	;
	; CHECK FOR INCREMENT TBLX
	;
CHKDWN 
	LDX #NWRAP
	       LDA #LLEN-1
DWNCHK 
	CMP PNTR
	       BEQ DNLINE
	       CLC
	       ADC #LLEN
	       DEX
	       BNE DWNCHK
	       RTS
	;
DNLINE 
	LDX TBLX
	       CPX #NLINES
	       BEQ DWNBYE
	       INC TBLX
	;
DWNBYE 
	RTS
CHKCOL
	       LDX #15         ;THERE'S 15 COLORS
CHK1A          CMP COLTAB,X
	       BEQ CHK1B
	       DEX
	       BPL CHK1A
	       RTS
	;
CHK1B
	       STX COLOR       ;CHANGE THE COLOR
	       RTS
COLTAB
	;BLK,WHT,RED,CYAN,MAGENTA,GRN,BLUE,YELLOW
!byte   $90,$05,$1C,$9F,$9C,$1E,$1F,$9E
!byte   $81,$95,$96,$97,$98,$99,$9A,$9B

	;SCREEN SCROLL ROUTINE
	;
SCROL 
	LDA SAL
	PHA
	LDA    SAH
	PHA
	LDA    EAL
	PHA
	LDA    EAH
	PHA
	;
	;   S C R O L L   U P
	;
SCRO0 
	LDX #$FF
	       DEC TBLX
	       DEC LSXP
	       DEC LINTMP
SCR10 
	INX             ;GOTO NEXT LINE
	       JSR SETPNT      ;POINT TO 'TO' LINE
	       CPX #NLINES-1   ;DONE?
	       BCS SCR41       ;BRANCH IF SO
	;
	       LDA LDTB2+1,X   ;SETUP FROM PNTR
	       STA SAL
	       LDA LDTB1+1,X
	       JSR SCRLIN      ;SCROLL THIS LINE UP1
	       BMI SCR10
	;
SCR41
	       JSR CLRLN
	;
	LDX    #0              ;SCROLL HI BYTE POINTERS
SCRL5 
	LDA LDTB1,X
	AND    #$7F
	LDY    LDTB1+1,X
	BPL    SCRL3
	ORA    #$80
SCRL3 
	STA LDTB1,X
	INX
	CPX    #NLINES-1
	BNE    SCRL5
	;
	LDA    LDTB1+NLINES-1
	ORA    #$80
	STA    LDTB1+NLINES-1
	LDA    LDTB1           ;DOUBLE LINE?
	BPL    SCRO0           ;YES...SCROLL AGAIN
	;
	       INC TBLX
	       INC LINTMP
	       LDA #$7F        ;CHECK FOR CONTROL KEY
	       STA COLM        ;DROP LINE 2 ON PORT B
	       LDA ROWS
	       CMP #$FB        ;SLOW SCROLL KEY?(CONTROL)
	       PHP             ;SAVE STATUS. RESTORE PORT B
	       LDA #$7F        ;FOR STOP KEY CHECK
	       STA COLM
	       PLP
	BNE    MLP42
	;
	LDY    #0
MLP4  
	NOP             ;DELAY
	DEX
	BNE    MLP4
	DEY
	BNE    MLP4
	STY    NDX             ;CLEAR KEY QUEUE BUFFER
	;
MLP42 
	LDX TBLX
	;
PULIND
	PLA             ;RESTORE OLD INDIRECTS
	STA    EAH
	PLA
	STA    EAL
	PLA
	STA    SAH
	PLA
	STA    SAL
	RTS
NEWLIN
	       LDX TBLX
BMT1  
	INX
	; CPX #NLINES ;EXCEDED THE NUMBER OF LINES ???
	; BEQ BMT2 ;VIC-40 CODE
	       LDA LDTB1,X     ;FIND LAST DISPLAY LINE OF THIS LINE
	       BPL BMT1        ;TABLE END MARK=>$FF WILL ABORT...ALSO
BMT2  
	STX LINTMP      ;FOUND IT
	;GENERATE A NEW LINE
	CPX    #NLINES-1       ;IS ONE LINE FROM BOTTOM?
	BEQ    NEWLX           ;YES...JUST CLEAR LAST
	BCC    NEWLX           ;<NLINES...INSERT LINE
	       JSR SCROL       ;SCROLL EVERYTHING
	       LDX LINTMP
	       DEX
	       DEC TBLX
	       JMP WLOG30
NEWLX 
	LDA SAL
	PHA
	LDA    SAH
	PHA
	LDA    EAL
	PHA
	LDA    EAH
	PHA
	       LDX #NLINES
SCD10 
	DEX
	       JSR SETPNT      ;SET UP TO ADDR
	       CPX LINTMP
	       BCC SCR40
	       BEQ SCR40       ;BRANCH IF FINISHED
	       LDA LDTB2-1,X   ;SET FROM ADDR
	       STA SAL
	       LDA LDTB1-1,X
	       JSR SCRLIN      ;SCROLL THIS LINE DOWN
	       BMI SCD10
SCR40
	       JSR CLRLN
	       LDX #NLINES-2
SCRD21
	       CPX LINTMP      ;DONE?
	       BCC SCRD22      ;BRANCH IF SO
	       LDA LDTB1+1,X
	       AND #$7F
	       LDY LDTB1,X     ;WAS IT CONTINUED
	       BPL SCRD19      ;BRANCH IF SO
	       ORA #$80
SCRD19
	STA LDTB1+1,X
	       DEX
	       BNE SCRD21
SCRD22
	       LDX LINTMP
	       JSR WLOG30
	;
	       JMP PULIND      ;GO PUL OLD INDIRECTS AND RETURN
	;
	; SCROLL LINE FROM SAL TO PNT
	; AND COLORS FROM EAL TO USER
	;
SCRLIN
               ; we AND with $07 instead of $03 because we have 8
               ; pages instead of the usual 4
	       AND #$07        ;CLEAR ANY GARBAGE STUFF
	       ORA HIBASE      ;PUT IN HIORDER BITS
	       STA SAL+1
	       JSR TOFROM      ;COLOR TO & FROM ADDRS

	; it's more efficient to scroll screen and color
	; separately for kawari since we can use two
	; mem ptrs

	       LDY #LLEN-1
	       JSR PNT_TO_VMEM_A
	       JSR SAL_TO_VMEM_B
SCD20_PNT
	       ;LDA (SAL),Y
               STY VMEM_B_IDX
               LDA VMEM_B_VAL
	       ;STA (PNT),Y
               STY VMEM_A_IDX
               STA VMEM_A_VAL
	       DEY
	       BPL SCD20_PNT

	       LDY #LLEN-1
	       JSR USER_TO_VMEM_A
	       JSR EAL_TO_VMEM_B
SCD20_USER
	       ;LDA (EAL),Y
               STY VMEM_B_IDX
               LDA VMEM_B_VAL
	       ;STA (USER),Y
               STY VMEM_A_IDX
               STA VMEM_A_VAL
	       DEY
	       BPL SCD20_USER

	       RTS
	;
	; DO COLOR TO AND FROM ADDRESSES
	; FROM CHARACTER TO AND FROM ADRS
	;
TOFROM
	       JSR SCOLOR
	       LDA SAL         ;CHARACTER FROM
	       STA EAL         ;MAKE COLOR FROM
	       LDA SAL+1
               ; we AND with $07 instead of $03 because we have 8
               ; pages instead of the usual 4
	       AND #$07
	       ORA #>VICCOL
	       STA EAL+1
	       RTS
	;
	; SET UP PNT AND Y
	; FROM .X
	;
SETPNT
	LDA LDTB2,X
	       STA PNT
	       LDA LDTB1,X
               ; we AND with $07 instead of $03 because we have 8
               ; pages instead of the usual 4
	       AND #$07
	       ORA HIBASE
	       STA PNT+1
	       RTS
	;
	; CLEAR THE LINE POINTED TO BY .X
	;
CLRLN 
	LDY #LLEN-1
	       JSR SETPNT
	       JSR SCOLOR
CLR10 
	JSR CPATCH      ;REVERSED ORDER FROM 901227-02
		JSR PNT_TO_VMEM_A
	       LDA #$20        ;STORE A SPACE
	       ;STA (PNT),Y     ;TO DISPLAY
		STY VMEM_A_IDX
		STA VMEM_A_VAL
	       DEY
	       BPL CLR10
	       RTS
	       NOP
	;
	;PUT A CHAR ON THE SCREEN
	;
DSPP  
	TAY             ;SAVE CHAR
	LDA    #2
	STA    BLNCT           ;BLINK CURSOR
	JSR    SCOLOR          ;SET COLOR PTR
	JSR PNT_TO_VMEM_A      ;set before char put in a
	TYA                    ;RESTORE CHAR
DSPP2 
	LDY PNTR        ;GET COLUMN
	;STA    (PNT),Y          ;CHAR TO SCREEN
	STY VMEM_A_IDX
	STA VMEM_A_VAL
	JSR USER_TO_VMEM_A
	TXA
	;STA    (USER),Y         ;COLOR TO SCREEN
	STY VMEM_A_IDX
	STA VMEM_A_VAL
	RTS
SCOLOR
	LDA PNT         ;GENERATE COLOR PTR
	STA    USER
	LDA    PNT+1
               ; we AND with $07 instead of $03 because we have 8
               ; pages instead of the usual 4
	AND    #$07
	ORA    #>VICCOL        ;VIC COLOR RAM
	STA    USER+1
	RTS

new_cinv
KEY    JSR $FFEA       ;UPDATE JIFFY CLOCK
       LDA BLNSW       ;BLINKING CRSR ?
       BNE KEY4        ;NO
       DEC BLNCT       ;TIME TO BLINK ?
       BNE KEY4        ;NO
       LDA #20         ;RESET BLINK COUNTER
 
REPDO  STA BLNCT
       LDY PNTR        ;CURSOR POSITION
       LSR BLNON       ;CARRY SET IF ORIGINAL CHAR
       LDX GDCOL       ;GET CHAR ORIGINAL COLOR
       JSR PNT_TO_VMEM_A
       ;LDA (PNT),Y      ;GET CHARACTER
       STY VMEM_A_IDX
       LDA VMEM_A_VAL
       BCS KEY5        ;BRANCH IF NOT NEEDED
 
       INC BLNON       ;SET TO 1
       STA GDBLN       ;SAVE ORIGINAL CHAR
       JSR SCOLOR
 
       ;LDA (USER),Y     ;GET ORIGINAL COLOR
       JSR USER_TO_VMEM_A
       STY VMEM_A_IDX
       LDA VMEM_A_VAL
       STA GDCOL       ;SAVE IT
 
       LDX COLOR       ;BLINK IN THIS COLOR
       JSR PNT_TO_VMEM_A ; set ptr before setting a for dspp2
       LDA GDBLN       ;WITH ORIGINAL CHARACTER
KEY5   EOR #$80        ;BLINK IT
       JSR DSPP2       ;DISPLAY IT

KEY4   JMP $EA61


PNT_TO_VMEM_A
        LDA PNT
        STA VMEM_A_LO
	LDA PNT+1
        STA VMEM_A_HI
	RTS

SAL_TO_VMEM_B
        LDA SAL
        STA VMEM_B_LO
	LDA SAL+1
        STA VMEM_B_HI
	RTS

USER_TO_VMEM_A
        LDA USER
        STA VMEM_A_LO
	LDA USER+1
        STA VMEM_A_HI
	RTS

USER_TO_VMEM_B
        LDA USER
        STA VMEM_B_LO
	LDA USER+1
        STA VMEM_B_HI
	RTS

EAL_TO_VMEM_B
        LDA EAL
        STA VMEM_B_LO
	LDA EAL+1
        STA VMEM_B_HI
	RTS


LINZ0  = KAWARI_VICSCN
LINZ1  = LINZ0+LLEN
LINZ2  = LINZ1+LLEN
LINZ3  = LINZ2+LLEN
LINZ4  = LINZ3+LLEN
LINZ5  = LINZ4+LLEN
LINZ6  = LINZ5+LLEN
LINZ7  = LINZ6+LLEN
LINZ8  = LINZ7+LLEN
LINZ9  = LINZ8+LLEN
LINZ10 = LINZ9+LLEN
LINZ11 = LINZ10+LLEN
LINZ12 = LINZ11+LLEN
LINZ13 = LINZ12+LLEN
LINZ14 = LINZ13+LLEN
LINZ15 = LINZ14+LLEN
LINZ16 = LINZ15+LLEN
LINZ17 = LINZ16+LLEN
LINZ18 = LINZ17+LLEN
LINZ19 = LINZ18+LLEN
LINZ20 = LINZ19+LLEN
LINZ21 = LINZ20+LLEN
LINZ22 = LINZ21+LLEN
LINZ23 = LINZ22+LLEN
LINZ24 = LINZ23+LLEN

;****** SCREEN LINES LO BYTE TABLE ******
;
LDTB2
       !BYTE <LINZ0
       !BYTE <LINZ1
       !BYTE <LINZ2
       !BYTE <LINZ3
       !BYTE <LINZ4
       !BYTE <LINZ5
       !BYTE <LINZ6
       !BYTE <LINZ7
       !BYTE <LINZ8
       !BYTE <LINZ9
       !BYTE <LINZ10
       !BYTE <LINZ11
       !BYTE <LINZ12
       !BYTE <LINZ13
       !BYTE <LINZ14
       !BYTE <LINZ15
       !BYTE <LINZ16
       !BYTE <LINZ17
       !BYTE <LINZ18
       !BYTE <LINZ19
       !BYTE <LINZ20
       !BYTE <LINZ21
       !BYTE <LINZ22
       !BYTE <LINZ23
       !BYTE <LINZ24
