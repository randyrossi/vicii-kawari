!to "vmem-49152.prg",cbm

; HOWTO
;
; To poke a vmem address from BASIC use
;
;    SYS 49152,ADDR,VAL
;
; To peek a vmem address from BASIC use
;
;    SYS 49155,ADDR,0:VAL=PEEK(780)
;
; If you need VMEM A pointers to remain in-tact
; then use the 'safe' versions for POKE/PEEK 
; at 49158 and 49161 respectively.

; Some VICII-Kawari registers
KAWARI_VMODE1 = $d037
KAWARI_VMODE2 = $d038
KAWARI_PORT = $d03f

KAWARI_VICSCN = $1000 ; screen ram in KAWARI space

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

*=$c000
   ; $c000 = SYS 49152,LOC,VAL = Unafe VPOKE $HILO, VAL
   JMP poke_unsafe   ; $c000
   ; $c006 = SYS 49155,LOC,0 = Unsafe VPEEK $HILO (return $30c)
   JMP peek_unsafe     ; $c006
   ; $c003 = SYS 49158,LOC,VAL = Safe VPOKE $HILO, VAL
   JMP poke_safe   ; $c003
   ; $c009 = SYS 49161,LOC,0 = Safe VPEEK $HILO (return $30c)
   JMP peek_safe   ; $c009

SAVE_A_IDX    !BYTE 0
SAVE_A_HI     !BYTE 0
SAVE_A_LO     !BYTE 0
PEEK_RETURN   !BYTE 0

poke_safe:
   jsr save
   jsr poke_params
   jsr restore
   rts

poke_unsafe:
   jsr poke_params
   rts

peek_safe:
   jsr save
   jsr peek_params
   jsr restore
   lda PEEK_RETURN
   rts

peek_unsafe:
   jsr peek_params
   rts
   
; get SYS parameters and perform VMEM POKE
poke_params:
   jsr $aefd   ; check for comma
   jsr $b7eb   ; put params into $14,$15,X
   lda $14
   sta VMEM_A_LO
   lda $15
   sta VMEM_A_HI
   lda #0
   sta VMEM_A_IDX
   stx VMEM_A_VAL
   rts 

; b79e single param
peek_params:
   jsr $aefd   ; check for comma
   jsr $b7eb   ; put params into $14,$15
   lda $14
   sta VMEM_A_LO
   lda $15
   sta VMEM_A_HI
   lda #0
   sta VMEM_A_IDX
   lda VMEM_A_VAL
   sta PEEK_RETURN
   rts

save:
   lda VMEM_A_IDX
   sta SAVE_A_IDX
   lda VMEM_A_HI
   sta SAVE_A_HI
   lda VMEM_A_LO
   sta SAVE_A_LO
   rts

restore:
   lda SAVE_A_IDX
   sta VMEM_A_IDX
   lda SAVE_A_HI
   sta VMEM_A_HI
   lda SAVE_A_LO
   sta VMEM_A_LO
   rts
