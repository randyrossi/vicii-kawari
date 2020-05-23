!to "scroll.prg",cbm

; Hello World with raster interrupt colour band
; cobbled together from many examples and sources

  *=$8000

  BORDER=$d020    ; Screen border colour
  SCREEN=$d021    ; Screen background colour

  lda #$01        ; Enable VIC Shadow
  sta $d3ff

repeat:
  ldy #7
loop:
  lda $d016
  and #252
  sta $0810
  tya
  ora $0810
  sta $d016
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  dey
  bne loop

loop2:
  lda $d011
  and #252
  sta $0810
  tya
  ora $0810
  sta $d011
  iny
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  tya
  cmp #8
  bne loop2

  jmp repeat
