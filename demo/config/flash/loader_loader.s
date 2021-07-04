; The loader routine to load the fast loader loader.prg
; TODO: We can do this directly from C. No need for this file.

_load_loader:
        jsr $FFBD ; SETNAM
        lda #4    ; logical num
        ldx DRIVENUM
        ldy #1    ; secondary
        jsr $FFBA ; SETLFS
        lda #0    ; LOAD = 0, VERIFY = 1
        ldx #$00
        ldy #$90
        jsr $FFD5 ; do LOAD
        rts

DRIVENUM:
.BYTE           08

.export _load_loader

