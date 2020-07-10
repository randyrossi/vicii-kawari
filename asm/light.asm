!to "light.prg",cbm

*=$8000

; set colors
	lda #1		; white
	sta $d020	; border
	sta $d021	; background

; setup bank
	lda #2		; bank 2
	sta $dd00

; setup graphics location
	lda #120	; graphics location
	sta $d018

; setup bitmap graphics mode
	lda $d011	; bmm
	ora #$32
	sta $d011

; clear color mem
	lda #$12
	sta clear_value

	lda #$e8	; ctr
	sta ctr_low
	lda #$03
	sta ctr_high 

	lda #$00	; dest
	sta $fc
	lda #$5c
	sta $fd

	jsr clear

; clear graphics mem
	lda #255		; blank
	sta clear_value

	lda #$40
	sta ctr_low
	lda #$1f
	sta ctr_high 

	lda #$00	; dest
	sta $fc
	lda #$60
	sta $fd

	jsr clear

	
plotem:
	lda $d013
	sta x
	lda $d014
	sta y
	jsr plot
	jmp plotem

	rts

clear:
	ldx #0
cc_loop:
	lda clear_value
	sta ($fc,x)

	lda ctr_low
	cmp #00
	bne cc_no_wrap
	dec ctr_high
cc_no_wrap:
	dec ctr_low
	lda ctr_low
	bne ctr_cont
	lda ctr_high
	bne ctr_cont
	rts

ctr_cont
	inc $fc
	bne cc_loop
	inc $fd
	jmp cc_loop
	

add:
        clc             ;Ensure carry is clear
        lda vla+0       ;Add the two least significant bytes
        adc vlb+0
        sta res+0       ;... and store the result
        lda vla+1       ;Add the two most significant bytes
        adc vlb+1       ;... and any propagated carry bit
        sta res+1       ;... and store the result
	rts

vla: !byte 0
     !byte 0
vlb: !byte 0
     !byte 0
res: !byte 0
     !byte 0

multiply:
	  ; factors in factor1 and factor2
	lda #0
	ldx  #$8
	lsr  factor1
loop:
	bcc  no_add
	clc
	adc  factor2

no_add:
	ror
	ror  factor1
	dex
	bne  loop
	sta  factor2
	; done, high result in factor2, low result in factor1	
	rts

factor1:
	!byte 0
factor2:
	!byte 0

ctr_low:
	!byte 0
ctr_high:
	!byte 0
clear_value:
	!byte 0

x:
	!byte 0
y:
	!byte 0
x1:
	!byte 0
y1:
	!byte 0

x2_low: !byte 0
x2_high: !byte 0
y2_low: !byte 0
y2_high: !byte 0

plot:
	lda x		; x1 = x / 8
	lsr 
	lsr 
	lsr 
	sta x1

	lda y		; y1 = y / 8
	lsr
	lsr
	lsr 
	sta y1

	lda #160	; y2 = y1 * 160
	sta factor1
	lda y1
	sta factor2
	jsr multiply
	
	clc		; y2 = y2 * 2
	rol factor1
	rol factor2

	lda factor1
	sta y2_low
	lda factor2
	sta y2_high

	lda #8		; x2 = x1 * 8
	sta factor1
	lda x1
	sta factor2
	jsr multiply

	lda factor1
	sta x2_low
	lda factor2
	sta x2_high

	lda y2_low
	sta vla+0
	lda y2_high
	sta vla+1

	lda x2_low
	sta vlb+0
	lda x2_high
	sta vlb+1

	jsr add		; res = y2 * x2

	lda res		; vla = res
	sta vla+0
	lda res+1
	sta vla+1

	lda y		; vlb = y % 8
	and #7
	sta vlb+0
	lda #0
	sta vlb+1

	jsr add		; res = res = y % 8

	lda res+0	; vla = res
	sta vla+0
	lda res+1
	sta vla+1

	lda #$00	; vlb = $6000
	sta vlb+0
	lda #$60
	sta vlb+1

	jsr add		; res = res + $6000

	lda x		; a = x % 8
	and #7
	ldy #7

find_bit:
	cmp #0
	beq pokeit
	clc
	sbc #0
	dey
	jmp find_bit

pokeit:
	lda #1
pokeit2:
	cpy #0
	beq pokeit3
	asl
	dey
	jmp pokeit2

pokeit3:
	tay	; save it

	lda res+0
	sta $fc
	lda res+1
	sta $fd
	tya
	eor #$ff 
	ldx #0
	and ($fc,x)
	sta ($fc,x)
	
bit_done:
	rts
	
