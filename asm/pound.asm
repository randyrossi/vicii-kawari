!to "pound.prg",cbm

; Shove random bytes into vic registers

  *=$800

!byte $00,$0b,$08,$01,$00,$9e,$32,$30,$36,$31,$00,$00,$00

begin:
  ; start sync
  lda #1
  sta $d3ff

loop:
  ; 8100 is reg offset
  lda #$2e
  sta $8100

fill:
  ; gen a random byte into $64
  jsr $e09a
  lda $8100
  tax
  ; don't ever poke $1a to enable interrupts
  cpx #$1a
  beq skip
  lda $64
  sta $d000,x
skip
  dex
  txa
  sta $8100
  cmp #$ff
  bne fill 
  jmp loop
