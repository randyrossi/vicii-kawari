!to "xscroll.prg",cbm

; Futz with xscroll to make wavy/jittery text

  *=$8000

  lda #$01        ; Enable VIC Shadow
  sta $d3ff

repeat:
  ldy #7

loop:
  lda $d016
  and #248
  sta $0810
  tya
  ora $0810
  sta $d016
  ldx #50
del:
  dex
  bne del
  dey
  bne loop

loop2:
  lda $d016
  and #248
  sta $0810
  tya
  ora $0810
  sta $d016
  iny
  ldx #50
del2:
  dex
  bne del2
  tya
  cmp #8
  bne loop2

  jmp repeat
