activate_kawari:        
        ; Enable VICII-Kawari extensions
        lda #CHAR_V
        sta KAWARI_PORT
        lda #CHAR_I
        sta KAWARI_PORT
        lda #CHAR_C
        sta KAWARI_PORT
        lda #CHAR_2
        sta KAWARI_PORT
        rts

save_colors:
        ; remember old rgb
        lda #>oldrgb
        sta $fc
        ldy #<oldrgb
        sty $fb

        lda #64
        sta VMEM_A_LO

        ldy #0
savrgb
        lda VMEM_A_VAL
        sta ($fb),y
        inc VMEM_A_LO
        iny
        tya
        cmp #64
        bne savrgb

        ; remember old hsv
        lda #>oldhsv
        sta $fc
        ldy #<oldhsv
        sty $fb

        lda #$a0
        sta VMEM_A_LO

        ldy #0
savhsv
        lda VMEM_A_VAL
        sta ($fb),y
        inc VMEM_A_LO
        iny
        tya
        cmp #48
        bne savhsv
        rts

restore_colors:
        ; restore old rgb
        lda #>oldrgb
        sta $fc
        ldy #<oldrgb
        sty $fb

        lda #64
        sta VMEM_A_LO

        ldy #0
restrgb
        lda ($fb),y
        sta VMEM_A_VAL
        inc VMEM_A_LO
        iny
        tya
        cmp #64
        bne restrgb

        ; restore old hsv
        lda #>oldhsv
        sta $fc
        ldy #<oldhsv
        sty $fb

        lda #$a0
        sta VMEM_A_LO

        ldy #0
resthsv
        lda ($fb),y
        sta VMEM_A_VAL
        inc VMEM_A_LO
        iny
        tya
        cmp #48
        bne resthsv
        rts

oldrgb
!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

oldhsv
!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
!byte 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

