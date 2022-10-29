!to "grogu.prg",cbm

!source "kawari.inc"

KAWARI_VICSCN = $1000 ; screen ram in KAWARI space

*=$0801

BASIC:  !BYTE $0B,$08,$01,$00,$9E,$32,$30,$36,$33,$00,$00,$00,$00,$00
        ;Adds BASIC line: 1 SYS 2063

main
        jmp init

!source "kawari-util.inc"

init
        ; Enable VICII-Kawari extensions
        jsr activate_kawari

        ; Turn on hires 320x200 char_pixel_base doesn't matter
        lda #16+64
        sta KAWARI_VMODE1
        ; Bitmap takes entire 32k so vmode2 doesn't matter
        lda #0
        STA KAWARI_VMODE2

        ; now copy from DRAM into VICII-Kawari memory

        lda #>bitmap
        sta $fc
        lda #<bitmap
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

        lda #32
        sta KAWARI_PORT  ; make regs visible

        jsr save_colors

        lda #64     ; color regs start at 64
        sta VMEM_A_LO

        lda #>rgb
        sta $fc
        ldy #<rgb
        sty $fb
        ldy #0
loop3
        lda ($fb),y
        sta VMEM_A_VAL
        inc VMEM_A_LO
        iny
        tya
        cmp #64
        bne loop3

        lda #$a0     ; luma regs start at a0
        sta VMEM_A_LO
        lda #>hsv
        sta $fc
        ldy #<hsv
        sty $fb
        ldy #0
loop5
        lda ($fb),y
        sta VMEM_A_VAL
        inc VMEM_A_LO
        iny
        tya
        cmp #48
        bne loop5

wait
        jsr $ffe4
        cmp #0
        beq wait

        lda #0
        sta KAWARI_VMODE1

        lda #32
        sta KAWARI_PORT  ; make regs visible

        jsr restore_colors

        lda #0
        sta KAWARI_PORT
        rts

rgb
!binary "grogu-rgb.bin"

hsv
!binary "grogu-hsv.bin"

bitmap
!binary "grogu.bin"

