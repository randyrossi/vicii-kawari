!to "krps_rgb.prg",cbm

!source "kawari.inc"

*=$0801

BASIC:  !BYTE $0B,$08,$01,$00,$9E,$32,$30,$36,$33,$00,$00,$00,$00,$00
        ;Adds BASIC line: 1 SYS 2063

main
        jmp init

!source "kawari-util.inc"

init
        ; Enable VICII-Kawari extensions
        jsr activate_kawari

        LDA #0
        sta VMEM_A_IDX

        ; Load first 16k img data and copy to VMEM $0000
        LDA #$00
        sta VMEM_A_HI
        LDA #$00
        sta VMEM_A_LO
        LDA #img1_name_end-img1_name
        LDX #<img1_name
        LDY #>img1_name
        jsr load_copy_16k

        ; Load scond 16k img data and copy to VMEM $4000
        LDA #$40
        sta VMEM_A_HI
        LDA #$00
        sta VMEM_A_LO
        LDA #img2_name_end-img2_name
        LDX #<img2_name
        LDY #>img2_name
        jsr load_copy_16k
        
        ; Load rgb data and copy to VMEM $8000
        LDA #$00
        sta VMEM_A_LO
        LDA #$80
        sta VMEM_A_HI
        LDA #rgb_name_end-rgb_name
        LDX #<rgb_name
        LDY #>rgb_name
        jsr load_copy_16k

        lda #32
        sta KAWARI_PORT  ; make regs visible
        jsr save_colors

        ; hires 320x200
        lda #16+64
        sta KAWARI_VMODE1
        lda #0
        STA KAWARI_VMODE2

do_rps:
        lda #VMEM_FLAG_DMA+VMEM_FLAG_REGS_BIT
        sta KAWARI_MEM_FLAGS

        lda #<table_lo
        sta $fd
        lda #>table_lo
        sta $fe

        lda #<table_hi
        sta $fb
        lda #>table_hi
        sta $fc

        ; start of RGB color regs
        lda #$40
        sta VMEM_A_LO
        lda #$0         ; dest
        sta VMEM_A_HI

        ; install 16 colors (4 bytes each)
        lda #$40        ; num
        sta VMEM_A_IDX
        lda #$00
        sta VMEM_B_IDX

        lda #0
        sta $fa

        SEI
        LDA #%01111111
        STA $DC0D
        AND $D011
        STA $D011
        LDA $DC0D
        LDA $DD0D
        lda #50   ; raster interrupt every line 50
        sta $d012

        lda #$35
        sta $01

        LDA #<irq_handler
        STA $fffe
        LDA #>irq_handler
        STA $ffff

        LDA #%00000001
        STA $D019
        STA $D01A

        CLI

forever:
        jmp forever

irq_handler:
        ; acknowledge the raster interrupt
        LDA #%00000001
        STA $D019
        ; We've hit line 50. 
        ; TODO : Explain difference between RGB and Luma/Chroma modes
        ; to account for line buffer.
        lda #50
        tay
     
        ; firmware must be at least 1.16 for DMA to work
        ; against extra regs

        ; use raster line as index into table to 
        ; find hi/lo bytes of color for dma
        ; chase the raster lines down the screen, swapping
        ; in new colors for every line
        ; 65 cycles
        !for inner,200 {
           nop
           nop
           nop
           nop
           nop
           nop
           nop
           nop
           lda ($fd),y     ; lo
           sta VMEM_B_LO
           lda ($fb),y     ; hi
           lda ($fb),y     ; hi again for cycle count reasons
           sta VMEM_B_HI
           lda #1          ; should be around cycle 8 of the raster line
           sta VMEM_A_VAL
           nop
           nop
           nop
           nop
           nop
           lda #$40        ; put num bytes back after dma
           sta VMEM_A_IDX
           iny
        }

        rti

load_copy_16k:
        JSR $FFBD     ; call SETNAM
        LDA #$01
        LDX $BA       ; last used device number
        BNE .skip
        LDX #$08      ; default to device 8
.skip   LDY #$00      ; $00 means: load to new address
        JSR $FFBA     ; call SETLFS

        LDX #<scratch_space
        LDY #>scratch_space
        LDA #$00      ; $00 means: load to memory (not verify)
        JSR $FFD5     ; call LOAD
        BCS .error    ; if carry set, a load error has happened

; move
        lda #>scratch_space
        sta $fc
        lda #<scratch_space
        sta $fb

        lda #1      ; use auto increment
        sta KAWARI_PORT

        ldy #0
        ; copy loop, we copy 16k
        ldx #$40    ; we loop 64 times (64x256 = 16Kb)
loop2   lda ($fb),y ; read byte from src $fb/$fc
        sta VMEM_A_VAL   ; write byte to dest video ram
        iny         ; do this 256 times...
        bne loop2   ; ..for low byte $00 to $FF
        inc $fc     ; when we passed $FF increase high byte...
        dex         ; ... and decrease X by one before restart
        bne loop2   ; We repeat this until X becomes Zero

        RTS
.error
        ; most likely errors:
        ; A = $05 (DEVICE NOT PRESENT)
        ; A = $04 (FILE NOT FOUND)
        ; A = $1D (LOAD ERROR)
        ; A = $00 (BREAK, RUN/STOP has been pressed during loading)
        RTS

img1_name:  !TEXT "IMG1"
img1_name_end:

img2_name:  !TEXT "IMG2"
img2_name_end:

rgb_name:  !TEXT "RGB"
rgb_name_end:

!align 255,0
table_lo:    
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $40
    !BYTE $80
    !BYTE $c0
    !BYTE $00
    !BYTE $00
    !BYTE $00
    !BYTE $00
!align 255,0
table_hi:    
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $81
    !BYTE $81
    !BYTE $81
    !BYTE $81
    !BYTE $82
    !BYTE $82
    !BYTE $82
    !BYTE $82
    !BYTE $83
    !BYTE $83
    !BYTE $83
    !BYTE $83
    !BYTE $84
    !BYTE $84
    !BYTE $84
    !BYTE $84
    !BYTE $85
    !BYTE $85
    !BYTE $85
    !BYTE $85
    !BYTE $86
    !BYTE $86
    !BYTE $86
    !BYTE $86
    !BYTE $87
    !BYTE $87
    !BYTE $87
    !BYTE $87
    !BYTE $88
    !BYTE $88
    !BYTE $88
    !BYTE $88
    !BYTE $89
    !BYTE $89
    !BYTE $89
    !BYTE $89
    !BYTE $8a
    !BYTE $8a
    !BYTE $8a
    !BYTE $8a
    !BYTE $8b
    !BYTE $8b
    !BYTE $8b
    !BYTE $8b
    !BYTE $8c
    !BYTE $8c
    !BYTE $8c
    !BYTE $8c
    !BYTE $8d
    !BYTE $8d
    !BYTE $8d
    !BYTE $8d
    !BYTE $8e
    !BYTE $8e
    !BYTE $8e
    !BYTE $8e
    !BYTE $8f
    !BYTE $8f
    !BYTE $8f
    !BYTE $8f
    !BYTE $90
    !BYTE $90
    !BYTE $90
    !BYTE $90
    !BYTE $91
    !BYTE $91
    !BYTE $91
    !BYTE $91
    !BYTE $92
    !BYTE $92
    !BYTE $92
    !BYTE $92
    !BYTE $93
    !BYTE $93
    !BYTE $93
    !BYTE $93
    !BYTE $94
    !BYTE $94
    !BYTE $94
    !BYTE $94
    !BYTE $95
    !BYTE $95
    !BYTE $95
    !BYTE $95
    !BYTE $96
    !BYTE $96
    !BYTE $96
    !BYTE $96
    !BYTE $97
    !BYTE $97
    !BYTE $97
    !BYTE $97
    !BYTE $98
    !BYTE $98
    !BYTE $98
    !BYTE $98
    !BYTE $99
    !BYTE $99
    !BYTE $99
    !BYTE $99
    !BYTE $9a
    !BYTE $9a
    !BYTE $9a
    !BYTE $9a
    !BYTE $9b
    !BYTE $9b
    !BYTE $9b
    !BYTE $9b
    !BYTE $9c
    !BYTE $9c
    !BYTE $9c
    !BYTE $9c
    !BYTE $9d
    !BYTE $9d
    !BYTE $9d
    !BYTE $9d
    !BYTE $9e
    !BYTE $9e
    !BYTE $9e
    !BYTE $9e
    !BYTE $9f
    !BYTE $9f
    !BYTE $9f
    !BYTE $9f
    !BYTE $a0
    !BYTE $a0
    !BYTE $a0
    !BYTE $a0
    !BYTE $a1
    !BYTE $a1
    !BYTE $a1
    !BYTE $a1
    !BYTE $a2
    !BYTE $a2
    !BYTE $a2
    !BYTE $a2
    !BYTE $a3
    !BYTE $a3
    !BYTE $a3
    !BYTE $a3
    !BYTE $a4
    !BYTE $a4
    !BYTE $a4
    !BYTE $a4
    !BYTE $a5
    !BYTE $a5
    !BYTE $a5
    !BYTE $a5
    !BYTE $a6
    !BYTE $a6
    !BYTE $a6
    !BYTE $a6
    !BYTE $a7
    !BYTE $a7
    !BYTE $a7
    !BYTE $a7
    !BYTE $a8
    !BYTE $a8
    !BYTE $a8
    !BYTE $a8
    !BYTE $a9
    !BYTE $a9
    !BYTE $a9
    !BYTE $a9
    !BYTE $aa
    !BYTE $aa
    !BYTE $aa
    !BYTE $aa
    !BYTE $ab
    !BYTE $ab
    !BYTE $ab
    !BYTE $ab
    !BYTE $ac
    !BYTE $ac
    !BYTE $ac
    !BYTE $ac
    !BYTE $ad
    !BYTE $ad
    !BYTE $ad
    !BYTE $ad
    !BYTE $ae
    !BYTE $ae
    !BYTE $ae
    !BYTE $ae
    !BYTE $af
    !BYTE $af
    !BYTE $af
    !BYTE $af
    !BYTE $b0
    !BYTE $b0
    !BYTE $b0
    !BYTE $b0
    !BYTE $b1
    !BYTE $b1
    !BYTE $b1
    !BYTE $b1
    !BYTE $80
    !BYTE $80
    !BYTE $80
    !BYTE $80
scratch_space:
