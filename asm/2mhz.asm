!to "2mhz.prg",cbm

  *=$800

!byte $00,$0b,$08,$01,$00,$9e,$32,$30,$36,$31,$00,$00,$00

begin:
  lda #1
  sta $d020
  lda #86
  sta 53311
  lda #73
  sta 53311
  lda #67
  sta 53311
  lda #50
  sta 53311
  sei
  lda 53303
  ora #128
  sta 53303

  ldx #24
clear_snd
  lda #0
  sta 54272
  dex
  bne clear_snd
  lda #9
  sta 54272+5
  lda #0
  sta 54272+6
  lda #15
  sta 54272+24

  ldy #0
play
  lda dat,y
  sta 54272+1
  iny
  lda dat,y
  sta 54272
  iny
  lda #33
  sta 54272+4

  ldx #255
delay
  dex
  bne delay

  lda #32
  sta 54272+4

  ldx #255
delay2
  dex
  bne delay2

  inc $d020
  tya
  cmp #8
  bne play
  ldy #0
  jmp play
  
dat
!byte 25,177,28,214,25,177,28,214
