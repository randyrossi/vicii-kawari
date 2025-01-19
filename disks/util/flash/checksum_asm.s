
_check_6000:
        ; put first arg into pg_size
        sta pg_size+1

        lda $fc
        sta savefc
        lda $fb
        sta savefb

        lda #$60    ; load high byte of $6000
        sta $fc     ; store it in a free location we use as vector
        ldy #$00    ; init counter with 0
        sty $fb     ; store it as low byte in the $FB/$FC vector

        sty _chk1
        sty _chk2
        sty _chk3
        sty _chk4

        ; page size is overwritten by incoming arg in accum
pg_size:
        ldx #$40    ; outer loop this many times (16 times = 16Kb, 4 times = 4k)
loop:
        lda ($fb),y
        eor _chk1
        sta _chk1
        iny
        lda ($fb),y
        eor _chk2
        sta _chk2
        iny        
        lda ($fb),y 
        eor _chk3
        sta _chk3
        iny        
        lda ($fb),y 
        eor _chk4
        sta _chk4
        iny         
        bne loop

        inc $fc     ; when we passed $FF increase high byte...
        dex         ; ... and decrease X by one before restart
        bne loop    ; We repeat this until X becomes Zero

        lda savefb
        sta $fb
        lda savefc
        sta $fc

        rts

savefc:
.BYTE   0
savefb:
.BYTE   0

_chk1:
.BYTE   0
_chk2:
.BYTE   0
_chk3:
.BYTE   0
_chk4:
.BYTE   0

.export _check_6000
.export _chk1
.export _chk2
.export _chk3
.export _chk4
