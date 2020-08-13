!to "pound.prg",cbm

; Futz with yscroll to mess with badlines

  *=$8000


  lda #$f8
  and $d011
  and $d016

reset
  ldy #7
loop
  tya
  sta $d020
  sta $d021
  and $d011
  and $d016

  dey
  bne loop

  lda $d012
  sta $d011
  sta $d016
  sta $d018
  
  jmp reset
