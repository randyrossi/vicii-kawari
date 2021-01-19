!to "hires80.prg",cbm

  *=$8000

        ; Enable VICII-Kawari extensions
	lda #86
        sta $d03f
	lda #73
        sta $d03f
	lda #67
        sta $d03f
	lda #50
        sta $d03f

        sei         ; disable interrupts while we copy 
        ldx #$08    ; we loop 8 times (8x255 = 2Kb)
        lda #$33    ; make the CPU see the Character Generator ROM...
        sta $01     ; ...at $D000 by storing %00110011 into location $01
        lda #$d0    ; load high byte of $D000
        sta $fc     ; store it in a free location we use as vector
        ldy #$00    ; init counter with 0
        sty $fb     ; store it as low byte in the $FB/$FC vector

        lda #$C0    ; we're going to copy it to $C000
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
        lda #$c0    ; load high byte of $c000
        sta $fc     ; store it in a free location we use as vector
        ldy #$00    ; init counter with 0
        sty $fb     ; store it as low byte in the $FB/$FC vector

        lda #$00    ; we're going to copy it to video ram $0000
        sta $d03a
        lda #$00
        sta $d039
        lda #1      ; use auto increment
	sta $d03f

        ldx #$08    ; we loop 8 times (8x255 = 2Kb)
loop2   lda ($fb),y ; read byte from src $fb/$fc
        sta $d03b   ; write byte to dest video ram
        iny         ; do this 255 times...
        bne loop2   ; ..for low byte $00 to $FF
        inc $fc     ; when we passed $FF increase high byte...
        dex         ; ... and decrease X by one before restart
        bne loop2   ; We repeat this until X becomes Zero

        ; finally, turn on hires mode
        lda #16
	sta $d037

        cli         ; turn off interrupt disable flag
        rts         ; return from subroutine
