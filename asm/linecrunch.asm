!to "linecrunch.prg",cbm

; Hello World with raster interrupt colour band
; cobbled together from many examples and sources

  *=$8000

sei
        lda #$aa ; Just to make 3fff visible
        sta $3fff
        lda #$17 ; Make letters like 'y','g','p' visible in the linecrunch area
        sta $d018
loop1
        bit $d011 ; Wait for new frame
        bpl *-3
        bit $d011
        bmi *-3

        lda #$1b ; Set y-scroll to normal position (because we fcuk it up later on..)
        sta $d011

        jsr CalcNumLines ; Call sinus substitute routine

        lda #$51 ; Wait for position where we want LineCrunch to start
        cmp $d012
        bne *-3

        ldy #10 ; Wait one more line..
        dey
        bne *-1
        nop
        nop
        cmp $d012 ; ..and make a bit more stabel raster
        bne *+5
        bit 0
        nop

        ldx NumCrunchLines
        beq loop1 ; Skip if we want 0 crunched lines
loop2
        ldy #4 ; Wait some cycles
        dey
        bne *-1
        ldy 0

        lda $d012 ; Do one line of LineCrunch
        and #7
        ora #$18
        inc $d021 ; d021-indicator
        dec $d021
        sta $d011

        nop ; Wait some more cycles so that the whole loop ends up on 63 cycles (= one PAL raster line)
        nop
        nop
        nop

        dex ; Decrease counter
        beq loop1 ; Exit if we reached 0
        jmp loop2 ; Otherwise loop

CalcNumLines
        lda #0
        bpl *+4
        eor #$ff
        lsr
        lsr
        lsr
        sta NumCrunchLines
        inc CalcNumLines+1
        rts

NumCrunchLines
        !byte 0
