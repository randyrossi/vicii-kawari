!to "noborder.prg",cbm

  *=$C198

start
  SEI
  JSR initvic  ; init VIC
  LDA #<irqroutine      ; set up IRQ
  LDX #>irqroutine
  STA $0314
  STX $0315
  LDA #$1B
  STA $D011
  LDA #$f7
  STA $D012
  LDA #$01
  STA $D01A
  LDA #$7F
  STA $DC0D
  CLI
  RTS

initvic
  LDX #$00
loop1
  LDA data,X
  STA $D000,X   ; set first 16 values from table
  INX
  CPX #$10
  BNE loop1
  LDA #$FF
  STA $D015
  LDA #$00
  STA $D01C
  LDA #$00      ; no expansion
  STA $D017
  STA $D01D
  LDA #$FF      ; all x > 256
  STA $D010
  LDA #$F8
  LDX #$00
loop2
  STA $07F8,X
  CLC
  ADC #$01
  INX
  CPX #$08
  BNE loop2
  LDA #$0E
  LDX #$00
loop3
  STA $D027,X
  INX
  CPX #$08
  BNE loop3
  RTS

----------------------------------
; data set into VIC registers
data
   !byte  $00,$F7,$00,$F7,$00,$F7,$00,$F7
   !byte  $00,$F7,$00,$F7,$00,$F7,$00,$F7

----------------------------------
; main IRQ routine
irqroutine:
  LDX #$08
loop4
  DEX
  BNE loop4
  LDX #$30      ; 40 or so lines
  NOP           ; "timing"
  NOP
  ;NOP           ; uncomment for ntsc
  ;NOP           ; uncomment for ntsc
loop5
  NOP
  NOP
  DEC $D016     ; fiddle register
  INC $D016
  LDY $D012
  DEY
  NOP
  TYA
  AND #$07
  ORA #$18
  STA $D011
  BIT $EA
  NOP
  NOP
  DEX
  BPL loop5     ; repeat next line
  LDA #$1B
  STA $D011
  LDA #$01
  STA $D019
;C1EE  20 00 C0  JSR C000   # call main code
  JMP $EA31   ; finish IRQ
