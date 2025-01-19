; The loader routine to load the fast loader loader.prg
; TODO: We can do this directly from C. No need for this file.
; $a004

_load_loader:
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

.export _load_loader

