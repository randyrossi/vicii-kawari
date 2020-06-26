!to "pixel.prg",cbm

  *=$8000

        lda #2
	sta $dd00

	lda #120
	sta $d018

	lda $d011
	ora #32
	sta $d011

	lda #1		; color
	ldy #$00
l1
	sta $5c00,y
	dey
	bne l1

	ldy #$00
l2
	sta $5d00,y
	dey
	bne l2

	ldy #$00
l3
	sta $5e00,y
	dey
	bne l3

	ldy #$00
l4
	sta $5f00,y
	dey
	bne l4

	lda #$00
	sta $fc
	lda #$60
	sta $fd

	ldx #0
	lda #1

p1
	lda #$0
	sta ($fc,x)
	inc $fc
	bne p1

	inc $fd
	lda $fd
	cmp #$7f
	bne p1

p2
	lda #$0
	sta ($fc,x)
	inc $fc
	lda $fc
	cmp #40
	bne p2

	lda #16		; 1 = SHIFT0
	sta $6f64

	lda #97	; x  100 - SHIFT
	sta $d000
	lda #140	; y
	sta $d001
	lda #1		; sprite 1 en
	sta $d015
	lda #2		; red
	sta $d027

	lda #192
	sta $7f8

	lda #$ff	; make full sprite ff
	ldy #$3f
block
	sta $3000,y
	dey
	bne block
	

	lda $d01f
	
	lda #1
	sta $d3ff
	
coll
	lda $d01f ; check collision
	and #1
	bne done

	lda $d012 ; wait for raster 0
	cmp #0
	bne coll
	lda $d011
	and #$80
	cmp #0
	bne coll
	
	inc $d000

wait2
	lda $d012
	cmp #10
	bne wait2
	lda $d011
	and #$80
	cmp #0
	bne wait2

	jmp coll

done

        rts


pos
        !byte 0
