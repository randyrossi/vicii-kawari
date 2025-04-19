; The regular kernal loader routine to load a file
; into memory according to its load byte header

_kernal_load:
        jsr $FFBD ; SETNAM
        lda #4    ; logical num
        ldx DRIVENUM
        ldy #1    ; secondary - 1=use location bytes, 0=don't
        jsr $FFBA ; SETLFS
        lda #0    ; LOAD = 0, VERIFY = 1
        ldx #$04  ; ignored
        ldy #$a0  ; ignored
        jsr $FFD5 ; do LOAD
        bcs error
        ldx #0
        rts

error:
        ldx #1
        rts

DRIVENUM:
.BYTE           08

.export _kernal_load

