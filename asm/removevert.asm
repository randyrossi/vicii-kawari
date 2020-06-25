!to "removevert.prg",cbm

  *=$8000

sei

; First make sure the normal screen is shown.

bit $d011
bpl *-3
bit $d011
bmi *-3
lda #$1b
sta $d011

; Put dec 16 into $3fff
lda #16
sta $3fff

; For each frame, set screen-mode to 24 lines at y-position $f9 - $fa..
loop:
lda #$f9
cmp $d012
bne *-3
lda $d011
and #$f7
sta $d011

; .. and below y-position $fc, set it back to 25 lines.
bit $d011
bpl *-3
ora #8
sta $d011
jmp loop
