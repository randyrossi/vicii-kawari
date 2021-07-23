
!to "colorpal.prg",cbm

; Bytes to enable VICII-Kawari extensions
CHAR_V = 86
CHAR_I = 73
CHAR_C = 67
CHAR_2 = 50

; Some VICII-Kawari registers
KAWARI_VMODE1 = $d037
KAWARI_VMODE2 = $d038
KAWARI_PORT = $d03f

; Kawari video memory port A regs
VMEM_A_IDX = $d035
VMEM_A_HI = $d03a
VMEM_A_LO = $d039
VMEM_A_VAL = $d03b

; Kawari video memory port B regs
VMEM_B_IDX = $d036
VMEM_B_HI = $d03d
VMEM_B_LO = $d03c
VMEM_B_VAL = $d03e

BORDER=$d020    ; Screen border colour
SCREEN=$d021    ; Screen background colour

BANDTOP=140     ; Raster line to start band
BANDEND=160     ; Bottom raster line to switch back

*=$c000
   
        ; Enable VICII-Kawari extensions
        lda #CHAR_V
        sta KAWARI_PORT
        lda #CHAR_I
        sta KAWARI_PORT
        lda #CHAR_C
        sta KAWARI_PORT
        lda #CHAR_2
        sta KAWARI_PORT

  LDA #32         ; access regs
  STA KAWARI_PORT

  LDA #0
  STA VMEM_A_IDX  ; zero these out
  STA VMEM_B_IDX  ; zero these out
  STA VMEM_A_HI
  STA VMEM_B_HI

  ; light blue red and green register indices
  LDA #120
  STA VMEM_A_LO
  LDA #121
  STA VMEM_B_LO
  LDA #0
  STA $fc

  sei             ; Suspend interrupts during init

  LDA #$35
  STA $01


  lda #$7f        ; Disable CIA
  sta $dc0d

  lda $d01a       ; Enable raster interrupts
  ora #$01
  sta $d01a

  lda $d011       ; High bit of raster line cleared, we're
  and #$6f        ; only working within single byte ranges
  sta $d011

  lda #0          
  sta $d012

  lda #<myint    ; Push low and high byte of our routine into
  sta $fffe       ; IRQ vector addresses
  lda #>myint
  sta $ffff

  cli             ; Enable interrupts again

loop:
  jmp loop

myint:
  lda #8
  adc $d012
  sta $d012

noblue:
  ;INY
  INC VMEM_A_VAL
  ;DEX
  DEC VMEM_B_VAL

  lda #$ff        ; Acknowlege IRQ 
  sta $d019

  rti

