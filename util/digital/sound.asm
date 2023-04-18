!to "sound.prg",cbm

; Max compressed.bin size of 49000

*=$0801

BASIC:  !BYTE $0B,$08,$01,$00,$9E,$32,$30,$36,$33,$00,$00,$00,$00,$00
        ;Adds BASIC line: 1 SYS 2063

        lda $d011
        and #234
        sta $d011
start:
        sei       
        lda #53 ; turn off basic and kernel
        sta 1

	lda #$0f ;Setup attack=0 and decay=15
	sta $d405
	sta $d40c
	sta $d413
	lda #$ff ;Setup all sustain&release to 15
	sta $d406
	sta $d40d
	sta $d414
	lda #$49 ;Waveform is square, test bit set
	sta $d404
	sta $d40b
	sta $d412
	lda #$ff ;Filter cutoff as high as possible
	sta $d415
	sta $d416
	lda #$03 ;Enable voice 1 and 2 through filter
	sta $d417

	lda #<samples
	sta loop+1
	lda #>samples
	sta loop+2

loop:
        ldx samples
	ldy codebook1,x
	lda sid_6581,y
	sta $d418

	jsr delay
        ;nop    ; 2
        ;nop    ; 2
        ;nop    ; 2
        ;nop    ; 2

	ldy codebook2,x
	lda sid_6581,y
	sta $d418

	jsr delay
        ;nop    ; 2
        ;nop    ; 2
        ;nop    ; 2
        ;nop    ; 2

	ldy codebook3,x
	lda sid_6581,y
	sta $d418

	jsr delay
        ;nop    ; 2
        ;nop    ; 2
        ;nop    ; 2
        ;nop    ; 2

	ldy codebook4,x
	lda sid_6581,y
	sta $d418

	jsr delay
	inc loop+1  ; 6
        bne loop    ; 3

        inc loop+2  ; 6
        lda loop+2  ; 4
        cmp #$d0    ; 2
        bne loop    ; 3

        lda $d011
        ora #16
        sta $d011

        lda #55
        sta $1
	cli
        rts

delay:
!src "delay.inc"

!align 255, 0

; All these segments needs to be aligned to
; a page.

sid_6581:
!src "sidtable_6581.inc"
sid_8580:
!src "sidtable_8580.inc"
codebook1:
!bin "centroids1.bin"
codebook2:
!bin "centroids2.bin"
codebook3:
!bin "centroids3.bin"
codebook4:
!bin "centroids4.bin"
; 0xf00
samples:
!bin "compressed.bin"
