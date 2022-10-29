!to "split.prg",cbm

!source "kawari.inc"

*=$0801

BASIC:  !BYTE $0B,$08,$01,$00,$9E,$32,$30,$36,$33,$00,$00,$00,$00,$00
        ;Adds BASIC line: 1 SYS 2063

init
        jmp main

!source "kawari-util.inc"

main
        jsr activate_kawari

        lda 53303
        ora #8          ; Allow lores badlines
        sta 53303

        ; fill 32k video memory with a pic
        lda #0
        sta VMEM_A_IDX
        sta VMEM_A_HI
        sta VMEM_A_LO

        lda #0      ; use auto increment
        sta KAWARI_PORT

        lda #>img
        sta $fc
        lda #<img
        sta $fb

        lda #$00    ; we're going to copy it to video ram $0000
        sta VMEM_A_IDX
        sta VMEM_A_HI
        sta VMEM_A_LO
        lda #1      ; use auto increment
        sta KAWARI_PORT

        ldy #0
        ; copy bitmap loop
        ldx #$80    ; we loop 128 times (128x256 = 32Kb)
loop2   lda ($fb),y ; read byte from src $fb/$fc
        sta VMEM_A_VAL   ; write byte to dest video ram
        iny         ; do this 256 times...
        bne loop2   ; ..for low byte $00 to $FF
        inc $fc     ; when we passed $FF increase high byte...
        dex         ; ... and decrease X by one before restart
        bne loop2   ; We repeat this until X becomes Zero

        sei             ; Suspend interrupts during init

        lda #$7f        ; Disable CIA
        sta $dc0d

        lda $d01a       ; Enable raster interrupts
        ora #$01
        sta $d01a

        lda $d011       ; High bit of raster line cleared, we're
        and #$7f        ; only working within single byte ranges
        sta $d011

        lda #90         ; We want an interrupt at the top line
        sta $d012

        lda $0314
        sta irq_old_lo
        lda $0315
        sta irq_old_hi

        lda #<tohires    ; Push low and high byte of our routine into
        sta $0314       ; IRQ vector addresses
        lda #>tohires
        sta $0315

        cli             ; Enable interrupts again

loop:
        jsr $ffe4
        cmp #0
        bne exit
        jmp loop

exit:
        sei

        lda 53303       ; hires off
        and #175        ; turn off hires 320x200 
        sta 53303
        
        lda irq_old_lo
        sta $0314
        lda irq_old_hi
        sta $0315

        lda $d01a       ; Disable raster interrupts
        and #254
        sta $d01a

        lda #$ff
        sta $dc0d

        cli

        rts

tolores:
        lda #<tohires    ; Push next interrupt routine address for when we're done
        sta $0314
        lda #>tohires
        sta $0315

        lda index
        tay

        lda topl,y
        sta $d012
  
        lda 53303       ; hires off
        and #175        ; turn off hires 320x200 
        sta 53303

        lda #$ff        ; Acknowlege IRQ 
	sta $d019
        jmp $ea31       ; Return to normal IRQ handler

tohires:
        lda #<tolores   ; Push next interrupt routine address for when we're done
        sta $0314
        lda #>tolores
        sta $0315

        lda index
        tay

        lda botl,y
        sta $d012

        iny
        sty index

        lda 53303
        ora #16+64      ; hires 320x200 on
        sta 53303

        lda #$ff        ; Acknowlege IRQ 
        sta $d019
        jmp $ea31       ; Return to normal IRQ handler

index
!byte 0

img
!binary "lion.bin"

topl
!byte 90,91,92,93,94,96,97,98,99,100,102,103,104,105,106,107,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,127,128,129,130,130,131,132,132,133,134,134,135,135,136,136,137,137,137,138,138,138,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,139,138,138,138,137,137,137,136,136,135,135,134,134,133,132,132,131,130,130,129,128,127,127,126,125,124,123,122,121,120,119,118,117,116,115,114,113,112,111,110,109,107,106,105,104,103,102,100,99,98,97,96,94,93,92,91,90,89,88,87,86,84,83,82,81,80,78,77,76,75,74,73,71,70,69,68,67,66,65,64,63,62,61,60,59,58,57,56,55,54,53,53,52,51,50,50,49,48,48,47,46,46,45,45,44,44,43,43,43,42,42,42,41,41,41,41,41,41,41,41,41,41,41,41,41,41,41,41,41,42,42,42,43,43,43,44,44,45,45,46,46,47,48,48,49,50,50,51,52,53,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,73,74,75,76,77,78,80,81,82,83,84,86,87,88,89

botl:
!byte 250,249,249,249,249,249,249,249,249,248,248,248,247,247,247,246,246,245,245,244,244,243,242,242,241,240,240,239,238,237,237,236,235,234,233,232,231,230,229,228,227,226,225,224,223,222,221,220,219,217,216,215,214,213,212,210,209,208,207,206,204,203,202,201,200,199,198,197,196,194,193,192,191,190,188,187,186,185,184,183,181,180,179,178,177,176,175,174,173,172,171,170,169,168,167,166,165,164,163,163,162,161,160,160,159,158,158,157,156,156,155,155,154,154,153,153,153,152,152,152,151,151,151,151,151,151,151,151,151,151,151,151,151,151,151,151,151,152,152,152,153,153,153,154,154,155,155,156,156,157,158,158,159,160,160,161,162,163,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,183,184,185,186,187,188,190,191,192,193,194,196,197,198,199,200,201,202,203,204,206,207,208,209,210,212,213,214,215,216,217,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,237,238,239,240,240,241,242,242,243,244,244,245,245,246,246,247,247,247,248,248,248,249,249,249,249,249,249,249,249

irq_old_lo:
!byte 0
irq_old_hi:
!byte 0
old_cia:
!byte 0
