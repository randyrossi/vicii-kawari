KAWARI_VMODE1 = $d037
KAWARI_VMODE2 = $d038
KAWARI_PORT = $d03f
VMEM_A_IDX = $d035
VMEM_A_HI = $d03a
VMEM_A_LO = $d039
VMEM_A_VAL = $d03b
VMEM_B_IDX = $d036
VMEM_B_HI = $d03d
VMEM_B_LO = $d03c
VMEM_B_VAL = $d03e

; Copy 16k DRAM 5000 to vmem 0000
_copy_5000_0000:
        sei         ; disable interrupts

        lda $fc
        sta savefc
        lda $fb
        sta savefb

        lda #$50    ; load high byte of $5000
        sta $fc     ; store it in a free location we use as vector
        ldy #$00    ; init counter with 0
        sty $fb     ; store it as low byte in the $FB/$FC vector

        lda #$00    ; we're going to copy it to video ram $0000
        sta VMEM_A_IDX
        sta VMEM_A_HI
        sta VMEM_A_LO
        lda #1      ; use auto increment
        sta KAWARI_PORT

        ldx #$40    ; we loop 64 times (64x256 = 16Kb)
loop:
        lda ($fb),y ; read byte from src $fb/$fc
        sta VMEM_A_VAL   ; write byte to dest video ram
        iny         ; do this 256 times...
        bne loop    ; ..for low byte $00 to $FF
        inc $fc     ; when we passed $FF increase high byte...
        dex         ; ... and decrease X by one before restart
        bne loop    ; We repeat this until X becomes Zero

        cli         ; turn off interrupt disable flag

        lda savefb
        sta $fb
        lda savefc
        sta $fc

        rts

; Fill DRAM 16k @5000 with addr % 256
_fill_5000:
        sei         ; disable interrupts

        lda $fc
        sta savefc
        lda $fb
        sta savefb

        lda #$50    ; load high byte of $5000
        sta $fc     ; store it in a free location we use as vector
        ldy #$00    ; init counter with 0
        sty $fb     ; store it as low byte in the $FB/$FC vector

        ldx #$40    ; we loop 64 times (64x256 = 16Kb)
loop2:
        tya
        sta ($fb),y ; write byte to $fb/$fc
        iny         ; do this 256 times...
        bne loop2    ; ..for low byte $00 to $FF
        inc $fc     ; when we passed $FF increase high byte...
        dex         ; ... and decrease X by one before restart
        bne loop2    ; We repeat this until X becomes Zero

        cli         ; turn off interrupt disable flag

        lda savefb
        sta $fb
        lda savefc
        sta $fc

        rts

; Zero out 16k DRAM @ 5000
_zero_5000:
        sei         ; disable interrupts

        lda $fc
        sta savefc
        lda $fb
        sta savefb

        lda #$50    ; load high byte of $5000
        sta $fc     ; store it in a free location we use as vector
        ldy #$00    ; init counter with 0
        sty $fb     ; store it as low byte in the $FB/$FC vector

        ldx #$40    ; we loop 64 times (64x256 = 16Kb)
        lda #0
loop3:
        sta ($fb),y ; write byte to $fb/$fc
        iny         ; do this 256 times...
        bne loop3    ; ..for low byte $00 to $FF
        inc $fc     ; when we passed $FF increase high byte...
        dex         ; ... and decrease X by one before restart
        bne loop3    ; We repeat this until X becomes Zero

        cli         ; turn off interrupt disable flag

        lda savefb
        sta $fb
        lda savefc
        sta $fc

        rts

; Test vmem 16k @ 0000 has addr % 256
; Fastcall arg with ptr to unsigned char for return
; value. 0=success, 1=failure
_test_0000:
        sta retHi
        stx retLo
        
        lda #0
        sta 53281
        sei         ; disable interrupts

        lda $fc
        sta savefc
        lda $fb
        sta savefb

        lda #$00    ; we're going to copy it to video ram $0000
        sta VMEM_A_IDX
        sta VMEM_A_HI
        sta VMEM_A_LO
        lda #1      ; use auto increment
        sta KAWARI_PORT

        ldx #$40    ; we loop 64 times (64x256 = 16Kb)
loop4:
        lda VMEM_A_VAL
        sty compare+1
compare:
        cmp #0
        bne fail

        iny         ; do this 256 times...
        bne loop4   ; ..for low byte $00 to $FF
        inc $fc     ; when we passed $FF increase high byte...
        dex         ; ... and decrease X by one before restart
        bne loop4   ; We repeat this until X becomes Zero

        cli         ; turn off interrupt disable flag

        lda retHi
        sta $fb
        lda retLo
        sta $fc

        lda #0
        ldy #0
        sta ($fb),y

        lda savefb
        sta $fb
        lda savefc
        sta $fc

        rts

fail:
        lda retHi
        sta $fb
        lda retLo
        sta $fc

        lda #1
        ldy #0
        sta ($fb),y

        lda savefb
        sta $fb
        lda savefc
        sta $fc
        rts

savefc:
.BYTE   0
savefb:
.BYTE   0

retHi:
.BYTE   0
retLo:
.BYTE   0

.export _copy_5000_0000
.export _fill_5000
.export _zero_5000
.export _test_0000
