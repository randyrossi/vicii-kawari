!to "irq.prg",cbm

; Hello World with raster interrupt colour band
; cobbled together from many examples and sources

  *=$8000

  BORDER=$d020    ; Screen border colour
  SCREEN=$d021    ; Screen background colour

  BANDTOP=140     ; Raster line to start band
  BANDEND=160     ; Bottom raster line to switch back

  lda #$01        ; Enable VIC Shadow
  sta $d3ff

  jsr $e544       ; Clear screen

  lda #$06        ; Init screen and border to blue
  sta BORDER
  sta SCREEN

irqinit:
  sei             ; Suspend interrupts during init

  lda #$7f        ; Disable CIA
  sta $dc0d

  lda $d01a       ; Enable raster interrupts
  ora #$01
  sta $d01a

  lda $d011       ; High bit of raster line cleared, we're
  and #$7f        ; only working within single byte ranges
  sta $d011

  lda #BANDTOP    ; We want an interrupt at the top line
  sta $d012

  lda #<bluebg    ; Push low and high byte of our routine into
  sta $0314       ; IRQ vector addresses
  lda #>bluebg
  sta $0315

  cli             ; Enable interrupts again

init:             ; Little "Hello World" routine starts here
  ldx #$00

loop:
  lda text,x
  sta $0400+40*12,x
  inx
  cpx #40
  bne loop

wait:             ; Eternal do-nothing loop, we're done.
  jmp wait

text:
  !scr "              irq test prog!            "

whitebg:
  lda #<bluebg    ; Push next interrupt routine address for when we're done
  sta $0314
  lda #>bluebg
  sta $0315
  lda #BANDEND    ; Next IRQ is for the change back at the bottom
  sta $d012
  
  lda #$01        ; Set up to change colour to white
  jmp ack         ; Go to common code for IRQ handlers

bluebg:
  lda #<whitebg   ; Push next interrupt routine address for when we're done
  sta $0314
  lda #>whitebg
  sta $0315
  lda #BANDTOP    ; Next IRQ is for the top again
  sta $d012

  lda #$06        ; Colour value for blue

ack:              ; Expect A to hold desired colour already when hit
  sta BORDER      ; Set border and screen
  sta SCREEN

  lda #$ff        ; Acknowlege IRQ 
  sta $d019

  jmp $ea31       ; Return to normal IRQ handler

