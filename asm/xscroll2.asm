!to "xscroll2.prg",cbm

; Futz with xscroll to make wavy/jittery text

  *=$8000

  ldx #00
  lda #$18
l1
  sta $400,x
  dex
  bne l1

l2
  sta $500,x
  dex
  bne l2

l3
  sta $600,x
  dex
  bne l3

  ldx #$e8
l4
  sta $6ff,x
  dex
  bne l4


  ;lda #$01        ; Enable VIC Shadow
  ;sta $d3ff

repeat:
  ldy #7

loop:
  lda $d016
  and #248
  sta $0810
  tya
  ora $0810
  sta $d016
;  ldx #50
;del:
;  dex
;  bne del
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
;  ldx #50
;del2:
;  dex
;  bne del2
  tya
  cmp #8
  bne loop2

  jmp repeat
