!to "mode.prg",cbm

  *=$8000

loop
  lda #$20
  ora $d011
  sta $d011
  lda #$df
  and $d011
  sta $d011
jmp loop
