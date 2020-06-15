!to "yscroll.prg",cbm

; Futz with yscroll to mess with badlines

  *=$8000

poll2:
  lda $d012
  cmp #0
  bne poll2
poll:
  lda $d011
  and #$80
  cmp #0
  bne poll
  
  lda #$01        ; Enable VIC Shadow
  sta $d3ff

  lda $d011
  sta $8100

repeat:
  ldy #7
loop:
  tya
  ora $8100
  sta $d011
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
  jmp repeat
