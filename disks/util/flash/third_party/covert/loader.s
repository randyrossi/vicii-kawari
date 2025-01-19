;-------------------------------------------------------------------------------
; COVERT BITOPS Autoconfiguring Loader/Depacker V2.29
; with 1541/1571/1581/CMD FD/CMD HD/IDE64/Fastdrive-emu autodetection & support
;
; EXOMIZER 2 & 3 depack by Magnus Lind & Krill
; PUCRUNCH depack by Pasi Ojala
; 1581/CMD FD/CMD HD information from Ninja & DocBacardi /The Dreams
; 2MHz 2-bit transfer delay code by MagerValp
; Rest by Lasse Öörni
;
; Thanks to K.M/TABOO for inspiration on badline detection and 1-bit transfer,
; and Marko Mäkelä for his original irqloader.s (huge inspiration)
;-------------------------------------------------------------------------------

                processor 6502
		org $a004

;-------------------------------------------------------------------------------
; Include your loader configuration file at this point!
;-------------------------------------------------------------------------------
		include "cfg.s"

;-------------------------------------------------------------------------------
; Defines derived from the compile options (need not be changed)
;-------------------------------------------------------------------------------

loadtempreg     = zpbase2+0      ;Temp variables for the loader
bufferstatus    = zpbase2+1      ;Bytes in fastload buffer
fileopen        = zpbase2+2      ;File open indicator
fastloadstatus  = zpbase2+3      ;Fastloader active indicator

destlo          = zpbase+0
desthi          = zpbase+1

;-------------------------------------------------------------------------------
; Other defines
;-------------------------------------------------------------------------------

MW_LENGTH       = 32            ;Bytes in one M-W command

status          = $90           ;Kernal zeropage variables
messages        = $9d
fa              = $ba

acsbf           = $01           ;Diskdrive variables: Buffer 1 command
trkbf           = $08           ;Buffer 1 track
sctbf           = $09           ;Buffer 1 sector
iddrv0          = $12           ;Disk drive ID
drvtemp         = $06           ;Temp variable
id              = $16           ;Disk ID
buf             = $0400         ;Sector data buffer
drvstart        = $0500         ;Start of drivecode
drv_sendtblhigh = $0700         ;256 byte table for 2-bit send optimization
initialize      = $d005         ;Initialize routine in 1541 ROM

ciout           = $ffa8         ;Kernal routines
listen          = $ffb1
second          = $ff93
unlsn           = $ffae
talk            = $ffb4
tksa            = $ff96
untlk           = $ffab
acptr           = $ffa5
chkin           = $ffc6
chkout          = $ffc9
chrin           = $ffcf
chrout          = $ffd2
close           = $ffc3
open            = $ffc0
setmsg          = $ff90
setnam          = $ffbd
setlfs          = $ffba
clrchn          = $ffcc
getin           = $ffe4
load            = $ffd5
save            = $ffd8

;-------------------------------------------------------------------------------
; Resident portion of loader (routines that you're going to use at runtime)
;-------------------------------------------------------------------------------

		jmp initloader  ; $9000
		jmp loadfile    ; $9003

                if LOADFILE_UNPACKED > 0
;-------------------------------------------------------------------------------
; LOADFILE
;
; Loads an unpacked file
;
; Parameters: X (low),Y (high): Address of null-terminated filename
; Returns: C=0 OK, C=1 error (A holds errorcode)
; Modifies: A,X,Y
;-------------------------------------------------------------------------------

loadfile:       jsr openfile
                jsr getbyte             ;Get startaddress lowbyte
                bcs loadfile_fail       ;If EOF at first byte, error (file not found)
                sta destlo
                jsr getbyte             ;Get startaddress highbyte
                sta desthi
                ldy #$00
loadfile_loop:  jsr getbyte
                bcs loadfile_eof
                if LOAD_UNDER_IO > 0
                jsr disableio           ;Allow loading under I/O area
                endif
                sta (destlo),y
                if LOAD_UNDER_IO > 0
                jsr enableio
                endif
                iny
                bne loadfile_loop
                inc desthi
                jmp loadfile_loop
loadfile_eof:   cmp #$01                ;Returncode 0 = OK, others error
loadfile_fail:  
                rts
                endif

                if LOADFILE_EXOMIZER > 0
;-------------------------------------------------------------------------------
; LOADFILE_EXOMIZER
;
; Loads a file packed with EXOMIZER1/2/3
;
; Parameters: X (low),Y (high): Address of null-terminated filename
; Returns: C=0 OK, C=1 error (A holds errorcode)
; Modifies: A,X,Y
;-------------------------------------------------------------------------------

tabl_bi         = depackbuffer
tabl_lo         = depackbuffer+52
tabl_hi         = depackbuffer+104

zp_len_lo       = zpbase+0
zp_src_lo       = zpbase+1
zp_src_hi       = zpbase+2
zp_bits_lo      = zpbase+3
zp_bits_hi      = zpbase+4
zp_bitbuf       = zpbase+5
zp_dest_lo      = zpbase+6
zp_dest_hi      = zpbase+7

loadfile_exomizer_fail: rts
loadfile_exomizer:
                jsr openfile

  if EXOMIZER_VERSION_3 = 0

; -------------------------------------------------------------------
; Exomizer 1/2
;
; This source code is altered and is not the original version found on
; the Exomizer homepage.
; It contains modifications made by Krill/Plush to decompress a compressed file
; compressed forward and to work with his loader.

;
; Copyright (c) 2002 - 2005 Magnus Lind.
;
; This software is provided 'as-is', without any express or implied warranty.
; In no event will the authors be held liable for any damages arising from
; the use of this software.
;
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
;
;   1. The origin of this software must not be misrepresented; you must not
;   claim that you wrote the original software. If you use this software in a
;   product, an acknowledgment in the product documentation would be
;   appreciated but is not required.
;
;   2. Altered source versions must be plainly marked as such, and must not
;   be misrepresented as being the original software.
;
;   3. This notice may not be removed or altered from any distribution.
;
;   4. The names of this software and/or it's copyright holders may not be
;   used to endorse or promote products derived from this software without
;   specific prior written permission.
;
; -------------------------------------------------------------------
; no code below this comment has to be modified in order to generate
; a working decruncher of this source file.
; However, you may want to relocate the tables last in the file to a
; more suitable address.
; -------------------------------------------------------------------

; -------------------------------------------------------------------
; jsr this label to decrunch, it will in turn init the tables and
; call the decruncher
; no constraints on register content, however the
; decimal flag has to be #0 (it almost always is, otherwise do a cld)
exomizer:
; -------------------------------------------------------------------
; init zeropage, x and y regs.
;
    ldy #0
    ldx #3
init_zp:
    jsr getbyte         ; preserve flags, exit on error
    bcs loadfile_exomizer_fail ; File not found error, only checked in the beginning
    sta zp_bitbuf-1,x
    dex
    bne init_zp

; -------------------------------------------------------------------
; calculate tables (50 bytes)
; x and y must be #0 when entering
;
nextone:
    inx
    tya
    and #$0f
    beq shortcut        ; start with new sequence

    txa             ; this clears reg a
    lsr             ; and sets the carry flag
    ldx tabl_bi-1,y
rolle:
    rol
    rol zp_bits_hi
    dex
    bpl rolle       ; c = 0 after this (rol zp_bits_hi)

    adc tabl_lo-1,y
    tax

    lda zp_bits_hi
    adc tabl_hi-1,y
shortcut:
    sta tabl_hi,y
    txa
    sta tabl_lo,y

    ldx #4
    jsr get_bits        ; clears x-reg.
    sta tabl_bi,y
    iny
    cpy #52
    bne nextone
    beq begin

; -------------------------------------------------------------------
; get bits (29 bytes)
;
; args:
;   x = number of bits to get
; returns:
;   a = #bits_lo
;   x = #0
;   c = 0
;   z = 1
;   zp_bits_hi = #bits_hi
; notes:
;   y is untouched
; -------------------------------------------------------------------
get_bits:
    lda #$00
    sta zp_bits_hi
    cpx #$01
    bcc bits_done
bits_next:
    lsr zp_bitbuf
    bne bits_ok
    pha
  if FORWARD_DECRUNCHING = 0
literal_get_byte:
    php
    jsr getbyte
    plp
    bcc literal_byte_gotten
  else
    jsr getbyte
    sec
  endif
    ror
    sta zp_bitbuf
    pla
bits_ok:
    rol
    rol zp_bits_hi
    dex
    bne bits_next
bits_done:
    rts

exomizer_eof:
    clc
    rts

  if FORWARD_DECRUNCHING > 0

; -------------------------------------------------------------------
; literal sequence handling, forward decrunching
;
literal_start:
    ldx #$10    ; these 16 bits
    jsr get_bits; tell the length of the sequence
literal_start1: ; if literal byte, a = 1, zp_bits_hi = 0
    sta zp_len_lo
    ldx zp_bits_hi

; -------------------------------------------------------------------
; main copy loop
; x = length hi
; y = length lo
;
copy_start:
    stx zp_bits_hi
    ldy #$00
copy_next:
  if LITERAL_SEQUENCES_NOT_USED = 0
    bcs copy_noliteral
    jsr getbyte
    dc.b $2c ; skip next instruction
copy_noliteral:
  endif
    lda (zp_src_lo),y
    sta (zp_dest_lo),y
    iny
    bne copy_nohigh
    dex
    inc zp_dest_hi
    inc zp_src_hi
copy_nohigh:
    tya
    eor zp_len_lo
    bne copy_next
    txa
    bne copy_next
    tya
    clc
    adc zp_dest_lo
    sta zp_dest_lo
    bcc copy_nocarry
    inc zp_dest_hi
copy_nocarry:
  else

; -------------------------------------------------------------------
; main copy loop
; x = length hi
; y = length lo
; (18(16) bytes)
;
copy_next_hi:
    dex
    dec zp_dest_hi
    dec zp_src_hi
copy_next:
    dey
  if LITERAL_SEQUENCES_NOT_USED = 0
    bcc literal_get_byte
  endif
    lda (zp_src_lo),y
literal_byte_gotten: ; y = 0 when this label is jumped to
    sta (zp_dest_lo),y
copy_start:
    tya
    bne copy_next
    txa
    bne copy_next_hi

  endif

; -------------------------------------------------------------------
; decruncher entry point, needs calculated tables (21(13) bytes)
; x and y must be #0 when entering
;
begin:
  if LITERAL_SEQUENCES_NOT_USED = 0
    ; literal sequence handling
    inx
    jsr get_bits
    tay
    bne literal_start1; if bit set, get a literal byte
  else
    dey
  endif
getgamma:
    inx
    jsr bits_next
    lsr
    iny
    bcc getgamma
  if LITERAL_SEQUENCES_NOT_USED > 0
    beq literal_start
  endif
    cpy #$11; 17

  if LITERAL_SEQUENCES_NOT_USED = 0
    ; literal sequence handling
  if FORWARD_DECRUNCHING > 0
    beq exomizer_eof  ; gamma = 17   : end of file
    bcs literal_start ; gamma = 18   : literal sequence
                      ; gamma = 1..16: sequence
  else ; backward decrunching
    bcc sequence_start; gamma = 1..16: sequence
    beq exomizer_eof  ; gamma = 17   : end of file
                      ; gamma = 18   : literal sequence
    ; -------------------------------------------------------------------
    ; literal sequence handling (13(2) bytes), backward decrunching
    ;
    ldx #$10    ; these 16 bits
    jsr get_bits; tell the length of the sequence
literal_start1: ; if literal byte, a = 1, zp_bits_hi = 0
    sta zp_len_lo
    ldx zp_bits_hi
    ldy #0
    bcc literal_start; jmp

sequence_start:
  endif; backward decrunching
  else
    bcs bits_done
  endif
; -------------------------------------------------------------------
; calulate length of sequence (zp_len) (11 bytes)
;
    ldx tabl_bi - 1,y
    jsr get_bits
    adc tabl_lo - 1,y   ; we have now calculated zp_len_lo
    sta zp_len_lo
; -------------------------------------------------------------------
; now do the hibyte of the sequence length calculation (6 bytes)
    lda zp_bits_hi
    adc tabl_hi - 1,y   ; c = 0 after this.
    pha
; -------------------------------------------------------------------
; here we decide what offset table to use (20 bytes)
; x is 0 here
;
    bne nots123
    ldy zp_len_lo
    cpy #$04
    bcc size123
nots123:
    ldy #$03
size123:
    ldx tabl_bit - 1,y
    jsr get_bits
    adc tabl_off - 1,y  ; c = 0 after this.
    tay         ; 1 <= y <= 52 here
; -------------------------------------------------------------------
  if FORWARD_DECRUNCHING = 0
; Here we do the dest_lo -= len_lo subtraction to prepare zp_dest
; but we do it backwards:   a - b == (b - a - 1) ^ ~0 (C-syntax)
; (16(16) bytes)
    lda zp_len_lo
literal_start:
    sbc zp_dest_lo
    bcc noborrow
    dec zp_dest_hi
noborrow:
    eor #$ff
    sta zp_dest_lo
    cpy #$01        ; y < 1 then literal
  if LITERAL_SEQUENCES_NOT_USED = 0
    bcc pre_copy
  else
    bcc literal_get_byte
  endif
  endif

; -------------------------------------------------------------------
; calulate absolute offset (zp_src)
;
    ldx tabl_bi,y
    jsr get_bits
    adc tabl_lo,y
    bcc skipcarry
    inc zp_bits_hi
  if FORWARD_DECRUNCHING > 0
skipcarry:
    sec
    eor #$ff
    adc zp_dest_lo
    sta zp_src_lo
    lda zp_dest_hi
    sbc zp_bits_hi
    sbc tabl_hi,y
    sta zp_src_hi
  else
    clc
skipcarry:
    adc zp_dest_lo
    sta zp_src_lo
    lda zp_bits_hi
    adc tabl_hi,y
    adc zp_dest_hi
    sta zp_src_hi
  endif

; -------------------------------------------------------------------
; prepare for copy loop (8(6) bytes)
;
    pla
    tax
  if LITERAL_SEQUENCES_NOT_USED = 0
    ; literal sequence handling
    sec
  if FORWARD_DECRUNCHING = 0
pre_copy:
    ldy zp_len_lo
  endif
    jmp copy_start
  else
    ldy zp_len_lo
    bcc copy_start
  endif
; -------------------------------------------------------------------
; two small static tables (6(6) bytes)
;
tabl_bit:
    dc.b 2,4,4
tabl_off:
    dc.b 48,32,16
; -------------------------------------------------------------------
; end of decruncher
; -------------------------------------------------------------------

                else

zp_len_hi       = zp_bits_lo

; -------------------------------------------------------------------
; Exomizer 3
;
; This source code is altered and is not the original version found on
; the Exomizer homepage. Forward decrunching modifications improved
; based on the version in Krill's loader.
; -------------------------------------------------------------------
;
; Copyright (c) 2002 - 2018 Magnus Lind.
;
; This software is provided 'as-is', without any express or implied warranty.
; In no event will the authors be held liable for any damages arising from
; the use of this software.
;
; Permission is granted to anyone to use this software for any purpose,
; including commercial applications, and to alter it and redistribute it
; freely, subject to the following restrictions:
;
;   1. The origin of this software must not be misrepresented; you must not
;   claim that you wrote the original software. If you use this software in a
;   product, an acknowledgment in the product documentation would be
;   appreciated but is not required.
;
;   2. Altered source versions must be plainly marked as such, and must not
;   be misrepresented as being the original software.
;
;   3. This notice may not be removed or altered from any distribution.
;
;   4. The names of this software and/or it's copyright holders may not be
;   used to endorse or promote products derived from this software without
;   specific prior written permission.
;
; -------------------------------------------------------------------
; no code below this comment has to be modified in order to generate
; a working decruncher of this source file.
; However, you may want to relocate the tables last in the file to a
; more suitable address.
; -------------------------------------------------------------------

; -------------------------------------------------------------------
; jsr this label to decrunch, it will in turn init the tables and
; call the decruncher
; no constraints on register content, however the
; decimal flag has to be #0 (it almost always is, otherwise do a cld)
exomizer:
; init zeropage, x and y regs. (12 bytes)
;
        ldy #0
        ldx #3
init_zp:
        jsr getbyte         ; preserve flags, exit on error
        bcs loadfile_exomizer_fail  ; File not found error, only checked in the beginning
        sta zp_bitbuf-1,x
        dex
        bne init_zp
; -------------------------------------------------------------------
; calculate tables (62 bytes) + get_bits macro
; x and y must be #0 when entering
;
table_gen:
        tax
        tya
        and #$0f
        sta tabl_lo,y
        beq shortcut            ; start a new sequence
; -------------------------------------------------------------------
        txa
        adc tabl_lo - 1,y
        sta tabl_lo,y
        lda zp_len_hi
        adc tabl_hi - 1,y
shortcut:
        sta tabl_hi,y
; -------------------------------------------------------------------
        lda #$01
        sta zp_len_hi
        lda #$78                ; %01111000
        jsr get_bits
; -------------------------------------------------------------------
        lsr
        tax
        beq rolled
        php
rolle:
        asl zp_len_hi
        sec
        ror
        dex
        bne rolle
        plp
rolled:
        ror
        sta tabl_bi,y
        bmi no_fixup_lohi
        lda zp_len_hi
        stx zp_len_hi
        dc.b $24
no_fixup_lohi:
        txa
; -------------------------------------------------------------------
        iny
        cpy #52
        bne table_gen
; -------------------------------------------------------------------
; prepare for main decruncher
        ldy zp_dest_lo
        stx zp_dest_lo
        stx zp_bits_hi

; -------------------------------------------------------------------
; copy one literal byte to destination (11 bytes)
;
literal_start1:
  if FORWARD_DECRUNCHING = 0
        tya
        bne no_hi_decr
        dec zp_dest_hi
no_hi_decr:
        dey
  endif
        jsr getbyte
  if LOAD_UNDER_IO > 0
        jsr disableio
  endif
        sta (zp_dest_lo),y
  if LOAD_UNDER_IO > 0
        jsr enableio
  endif
  if FORWARD_DECRUNCHING > 0
        iny
        bne no_hi_incr
        inc zp_dest_hi
no_hi_incr:
  endif
; -------------------------------------------------------------------
; fetch sequence length index (15 bytes)
; x must be #0 when entering and contains the length index + 1
; when exiting or 0 for literal byte
next_round:
        dex
        lda zp_bitbuf
no_literal1:
        asl
        bne nofetch8
        php
        jsr getbyte
        plp
        rol
nofetch8:
        inx
        bcc no_literal1
        sta zp_bitbuf
; -------------------------------------------------------------------
; check for literal byte (2 bytes)
;
        beq literal_start1
; -------------------------------------------------------------------
; check for decrunch done and literal sequences (4 bytes)
;
        cpx #$11
        bcs exit_or_lit_seq

; -------------------------------------------------------------------
; calulate length of sequence (zp_len) (18(11) bytes) + get_bits macro
;
        lda.wx tabl_bi - 1,x
        jsr get_bits
        adc tabl_lo - 1,x       ; we have now calculated zp_len_lo
        sta zp_len_lo
  if MAX_SEQUENCE_LENGTH_256 = 0
        lda zp_bits_hi
        adc tabl_hi - 1,x       ; c = 0 after this.
        sta zp_len_hi
; -------------------------------------------------------------------
; here we decide what offset table to use (27(26) bytes) + get_bits_nc macro
; z-flag reflects zp_len_hi here
;
        ldx zp_len_lo
  else
        tax
  endif
        lda #$e1
        cpx #$03
        bcs gbnc2_next
        lda tabl_bit,x
gbnc2_next:
        asl zp_bitbuf
        bne gbnc2_ok
        tax
        php
        jsr getbyte
        plp
        rol
        sta zp_bitbuf
        txa
gbnc2_ok:
        rol
        bcs gbnc2_next
        tax
; -------------------------------------------------------------------
; calulate absolute offset (zp_src) (21 bytes) + get_bits macro
;
  if MAX_SEQUENCE_LENGTH_256 = 0
        lda #0
        sta zp_bits_hi
  endif
  if FORWARD_DECRUNCHING = 0
        lda tabl_bi,x
        jsr get_bits
        adc tabl_lo,x
        sta zp_src_lo
        lda zp_bits_hi
        adc tabl_hi,x
        adc zp_dest_hi
        sta zp_src_hi
  else
        lda tabl_bi,x
        jsr get_bits
        clc
        adc tabl_lo,x
        eor #$ff
        sta zp_src_lo
        lda zp_bits_hi
        adc tabl_hi,x
        eor #$ff
        adc zp_dest_hi
        sta zp_src_hi
  endif

; -------------------------------------------------------------------
; prepare for copy loop (2 bytes)
;
pre_copy:
        ldx zp_len_lo
; -------------------------------------------------------------------
; main copy loop (30 bytes)
;
copy_next:
  if FORWARD_DECRUNCHING = 0
        tya
        bne copy_skip_hi
        dec zp_dest_hi
        dec zp_src_hi
copy_skip_hi:
        dey
  endif
  if LITERAL_SEQUENCES_NOT_USED = 0
  if FORWARD_DECRUNCHING > 0
        bcc get_literal_byte
    else
        bcs get_literal_byte
  endif
  endif
  if LOAD_UNDER_IO > 0
        jsr disableio
  endif
        lda (zp_src_lo),y
literal_byte_gotten:
        sta (zp_dest_lo),y
  if LOAD_UNDER_IO > 0
        jsr enableio
  endif
  if FORWARD_DECRUNCHING > 0
        iny
        bne copy_skip_hi
        inc zp_dest_hi
        inc zp_src_hi
copy_skip_hi:
  endif
        dex
        bne copy_next
  if MAX_SEQUENCE_LENGTH_256 = 0
        lda zp_len_hi
  endif
begin_stx:
        stx zp_bits_hi
  if (FORWARD_DECRUNCHING > 0 && MAX_SEQUENCE_LENGTH_256 = 0 && LITERAL_SEQUENCES_NOT_USED = 0) || LOAD_UNDER_IO > 0
        bne no_next_round
        jmp next_round
no_next_round:
  else
        beq next_round
  endif
  if MAX_SEQUENCE_LENGTH_256 = 0
copy_next_hi:
        dec zp_len_hi
        jmp copy_next
  endif
  if LITERAL_SEQUENCES_NOT_USED = 0
get_literal_byte:
        jsr getbyte
  if LOAD_UNDER_IO > 0
        jsr disableio
  endif
  if FORWARD_DECRUNCHING > 0
        bcc literal_byte_gotten
  else
        sec
        bcs literal_byte_gotten
  endif
  endif
; -------------------------------------------------------------------
; exit or literal sequence handling (16(12) bytes)
;
exit_or_lit_seq:
  if LITERAL_SEQUENCES_NOT_USED = 0
        beq exomizer_eof
        jsr getbyte
  if MAX_SEQUENCE_LENGTH_256 = 0
        sta zp_len_hi
  endif
        jsr getbyte
        tax
    if FORWARD_DECRUNCHING > 0
        bcc copy_next
    else
        sec
        bcs copy_next
    endif
exomizer_eof:
  endif
        clc
        rts

get_bits:
        adc #$80                ; needs c=0, affects v
        asl
        bpl gb_skip
gb_next:
        asl zp_bitbuf
        bne gb_ok
        pha
        php
        jsr getbyte
        plp
        rol
        sta zp_bitbuf
        pla
gb_ok:
        rol
        bmi gb_next
gb_skip:
        bvc gb_get_done
        sta zp_bits_hi
        jsr getbyte
        sec
gb_get_done:
        rts

; -------------------------------------------------------------------
; the static stable used for bits+offset for lengths 3, 1 and 2 (3 bytes)
; bits 4, 2, 4 and offsets 16, 48, 32
tabl_bit:
        dc.b %11100001, %10001100, %11100010
; -------------------------------------------------------------------
; end of decruncher
; -------------------------------------------------------------------
  endif

                endif

                if LOADFILE_PUCRUNCH > 0

;-------------------------------------------------------------------------------
; LOADFILE_PUCRUNCH
;
; Loads a file packed with PUCRUNCH
;
; Parameters: X (low),Y (high): Address of null-terminated filename
; Returns: C=0 OK, C=1 error (A holds errorcode)
; Modifies: A,X,Y
;-------------------------------------------------------------------------------

lzpos           = zpbase
bitstr          = zpbase+2

table           = depackbuffer

pucrunch_error: rts
loadfile_pucrunch:
                jsr openfile
                jsr getbyte                     ;Throw away file startaddress
                bcs pucrunch_error              ;Check file not found error in the beginning
                jsr getbyte

;-------------------------------------------------------------------------------
; PUCRUNCH DECOMPRESSOR by Pasi Ojala
;
; SHORT+IRQLOAD         354 bytes
; no rle =~             -83 bytes -> 271
; fixed params =~       -48 bytes -> 306
;                       223 bytes
; Parameters: -
; Returns: -
; Modifies: A,X,Y
;-------------------------------------------------------------------------------

        ldx #5
222$    jsr getbyt      ; skip 'p', 'u', endAddr HI&LO, leave starting escape in A
        dex
        bne 222$
        sta esc+1       ; starting escape
        jsr getbyt      ; read startAddr
        sta outpos+1
        jsr getbyt
        sta outpos+2
        jsr getbyt      ; read # of escape bits
        sta escB0+1
        sta escB1+1
        lda #8
        sec
        sbc escB1+1
        sta noesc+1     ; 8-escBits

        jsr getbyt
        sta mg+1        ; maxGamma + 1
        lda #9
        sec
        sbc mg+1        ; 8 - maxGamma == (8 + 1) - (maxGamma + 1)
        sta longrle+1
        jsr getbyt
        sta mg1+1       ; (1<<maxGamma)
        asl
        clc
        sbc #0
        sta mg21+1      ; (2<<maxGamma) - 1
        jsr getbyt
        sta elzpb+1

        ldx #$03
2$      jsr getbyt      ; Get 3 bytes, 2 unused (exec address)
        dex             ; and rleUsed. X is 0 after this loop
        bne 2$

        ;jsr getbyt     ; exec address
        ;sta lo+1       ; lo
        ;jsr getbyt
        ;sta hi+1       ; hi
        ;
        ;jsr getbyt     ; rleUsed
        ;ldx #0

        tay
        sty bitstr
0$      beq 1$          ; Y == 0 ?
        jsr getbyt
        sta table,x
        inx
        dey
        bne 0$
1$      ; setup bit store - $80 means empty
        lda #$80
        sta bitstr
        jmp main

getbyt  jsr getnew
        lda bitstr
        ror
        rts

newesc  ldy esc+1       ; remember the old code (top bits for escaped byte)
escB0   ldx #2          ; ** PARAMETER  0..8
        jsr getchkf     ; get & save the new escape code
        sta esc+1
        tya             ; pre-set the bits
        ; Fall through and get the rest of the bits.
noesc   ldx #6          ; ** PARAMETER  8..0
        jsr getchkf
        jsr putch       ; output the escaped/normal byte
        ; Fall through and check the escape bits again
main    ldy #0          ; Reset to a defined state
        tya             ; A = 0
escB1   ldx #2          ; ** PARAMETER  0..8
        jsr getchkf     ; X = 0
esc     cmp #0
        bne noesc
        ; Fall through to packed code

        jsr getval      ; X = 0
        sta lzpos       ; xstore - save the length for a later time
        lsr             ; cmp #1        ; LEN == 2 ? (A is never 0)
        bne lz77        ; LEN != 2      -> LZ77
        ;tya            ; A = 0
        jsr get1bit     ; X = 0
        lsr             ; bit -> C, A = 0
        bcc lz77_2      ; A=0 -> LZPOS+1
        ;***FALL THRU***

        ; e..e01
        jsr get1bit     ; X = 0
        lsr             ; bit -> C, A = 0
        bcc newesc      ; e..e010
        ;***FALL THRU***

        ; e..e011
srle    iny             ; Y is 1 bigger than MSB loops
        jsr getval      ; Y is 1, get len, X = 0
        sta lzpos       ; xstore - Save length LSB
mg1     cmp #64         ; ** PARAMETER 63-64 -> C clear, 64-64 -> C set..
        bcc chrcode     ; short RLE, get bytecode

longrle ldx #2          ; ** PARAMETER  111111xxxxxx
        jsr getbits     ; get 3/2/1 more bits to get a full byte, X = 0
        sta lzpos       ; xstore - Save length LSB

        jsr getval      ; length MSB, X = 0
        tay             ; Y is 1 bigger than MSB loops

chrcode jsr getval      ; Byte Code, X = 0
        tax             ; this is executed most of the time anyway
        lda table-1,x   ; Saves one jump if done here (loses one txa)

        cpx #32         ; 31-32 -> C clear, 32-32 -> C set..
        bcc 1$          ; 1..31, we got the right byte from the table

        ; Ranks 32..64 (11111°xxxxx), get byte..
        txa             ; get back the value (5 valid bits)
        ldx #3
        jsr getbits     ; get 3 more bits to get a full byte, X = 0

1$      ldx lzpos       ; xstore - get length LSB
        inx             ; adjust for cpx#$ff;bne -> bne
dorle   jsr putch
        dex
        bne dorle       ; xstore 0..255 -> 1..256
        dey
        bne dorle       ; Y was 1 bigger than wanted originally
mainbeq beq main        ; reverse condition -> jump always


lz77    jsr getval      ; X = 0
mg21    cmp #127        ; ** PARAMETER  Clears carry (is maximum value)
        bne noeof
eof:    clc             ; Loading ended OK
        rts

noeof   sbc #0          ; C is clear -> subtract 1  (1..126 -> 0..125)
elzpb   ldx #0          ; ** PARAMETER (more bits to get)
        jsr getchkf     ; clears Carry, X = 0

lz77_2  sta lzpos+1     ; offset MSB
        jsr getbyt2     ; clears Carry, X = 0
        ; Note: Already eor:ed in the compressor..
        ;eor #255       ; offset LSB 2's complement -1 (i.e. -X = ~X+1)
        adc outpos+1    ; -offset -1 + curpos (C is clear)
        ldx lzpos       ; xstore = LZLEN (read before it's overwritten)
        sta lzpos

        lda outpos+2
        sbc lzpos+1     ; takes C into account
        sta lzpos+1     ; copy X+1 number of chars from LZPOS to outpos+1
        ;ldy #0         ; Y was 0 originally, we don't change it

        inx             ; adjust for cpx#$ff;bne -> bne

lzslow  if LOAD_UNDER_IO > 0
        jsr disableio
        endif
        lda (lzpos),y   ; using abs,y is 3 bytes longer, only 1 cycle/byte faster
        jsr outpos
        iny             ; Y does not wrap because X=0..255 and Y initially 0
        dex
        bne lzslow      ; X loops, (256,1..255)
        jmp main

putch   if LOAD_UNDER_IO > 0
        jsr disableio
        endif
outpos  sta $aaaa       ; ** parameter
        inc outpos+1    ; ZP
        bne putchok
        inc outpos+2    ; ZP
putchok if LOAD_UNDER_IO > 0
        jmp enableio
        else
        rts
        endif

getnew  pha             ; 1 Byte/3 cycles
        jsr getbyte
0$      sec
        rol             ; Shift out the next bit and
                        ;  shift in C=1 (last bit marker)
        sta bitstr      ; bitstr initial value = $80 == empty
        pla             ; 1 Byte/4 cycles
        rts
        ; 25+12 = 37

; getval : Gets a 'static huffman coded' value
n; ** Scratches X, returns the value in A **
getval  inx             ; X <- 1
        txa             ; set the top bit (value is 1..255)
gv0     asl bitstr
        bne 1$
        jsr getnew
1$      bcc getchk      ; got 0-bit
        inx
mg      cpx #7          ; ** PARAMETER unary code maximum length + 1
        bne gv0
        beq getchk      ; inverse condition -> jump always
        ; getval: 18 bytes
        ; 15 + 17*n + 6+15*n+12 + 36*n/8 = 33 + 32*n + 36*n/8 cycles

; getbits: Gets X bits from the stream
; ** Scratches X, returns the value in A **
getbyt2 ldx #7
get1bit inx             ;2
getbits asl bitstr
        bne 1$
        jsr getnew
1$      rol             ;2
getchk  dex             ;2              more bits to get ?
getchkf bne getbits     ;2/3
        clc             ;2              return carry cleared
        rts             ;6+6

                endif

;-------------------------------------------------------------------------------
; OPENFILE
;
; Opens a file either with slow or fast loader. If a file is already open, does
; nothing!
;
; Parameters: X (low),Y (high): Address of null-terminated filename
; Returns: -
; Modifies: A,X,Y
;-------------------------------------------------------------------------------

openfile:       lda fileopen            ;A file already open?
                beq open_ok
                rts
open_ok:        if LONG_NAMES > 0
                stx destlo
                sty desthi
                else
                stx filename
                sty filename+1
                endif
                inc fileopen            ;File opened
                lda usefastload
                bne fastopen

;-------------------------------------------------------------------------------
; SLOWOPEN
;
; Opens a file without fastloader.
;
; Parameters: A:0 (it always is at this point)
; Returns: -
; Modifies: A,X,Y
;-------------------------------------------------------------------------------

slowopen:       if LONG_NAMES > 0
                tay
                endif
                jsr kernalon
                if LONG_NAMES > 0
slowopen_nameloop:
                iny
                lda (destlo),y
                bne slowopen_nameloop
                tya
                ldx destlo
                ldy desthi
                else
                lda #$03
                ldx #<filename
                ldy #>filename
                endif
                jsr setnam
                lda #$02
                ldy #$00
                jsr setlfsdevice
                jsr open
                ldx #$02                ;File number
                jsr chkin
                jmp kernaloff

;-------------------------------------------------------------------------------
; FASTOPEN
;
; Opens a file with fastloader. Uses an asynchronous protocol inspired by
; Marko Mäkelä's work when sending the filename.
;
; Parameters: -
; Returns: -
; Modifies: A,X,Y
;-------------------------------------------------------------------------------

fastopen:       jsr initfastload        ;If fastloader is not yet initted,
                                        ;init it now
                if LONG_NAMES > 0
                ldy #$00
fastload_sendouter:
                lda (destlo),y
                sta loadtempreg
                pha
                ldx #$08                ;Bit counter
                else
                ldx #$01
fastload_sendouter:
                ldy #$08                ;Bit counter
                endif
fastload_sendinner:
                bit $dd00               ;Wait for both DATA & CLK to go high
                bpl fastload_sendinner
                bvc fastload_sendinner
                if LONG_NAMES=0
                lsr filename,x
                else
                lsr loadtempreg
                endif
                lda #$10
                ora $dd00
                bcc fastload_zerobit
                eor #$30
fastload_zerobit:
                sta $dd00
                lda #$c0                ;Wait for CLK & DATA low (answer from
fastload_sendack:                       ;the diskdrive)
                bit $dd00
                bne fastload_sendack
                lda #$ff-$30            ;Set DATA and CLK high
                and $dd00
                sta $dd00
                if LONG_NAMES > 0
                dex
                bne fastload_sendinner
                iny
                pla
                bne fastload_sendouter
                else
                dey
                bne fastload_sendinner
                dex
                bpl fastload_sendouter
                endif
                sta $d07a               ;SCPU to slow mode
fastload_predelay:
                dex                     ;Delay to make sure the 1541 has
                bne fastload_predelay   ;set DATA high / CLK low before we continue

fastload_fillbuffer:
                ldx fileopen
                beq fileclosed
                pha
                sta $d07a               ;SCPU to slow mode

                if TWOBIT_PROTOCOL > 0
                ldx #$00
                lda #$03
                sta loadtempreg         ;And operand for NTSC delay
                endif

fastload_fbwait:bit $dd00               ;Wait for 1541 to signal data ready by
                bvc fastload_fbwait     ;setting CLK high

                if TWOBIT_PROTOCOL > 0
fastload_fbloop:sei
fastload_waitbadline:
                lda $d011               ;Check that a badline won't disturb
                clc                     ;the timing
                sbc $d012
                and #$07
                beq fastload_waitbadline
                lda $dd00
                ora #$10
                sta $dd00               ;CLK=low to begin transfer
fastload_delay: and #$03
                sta fastload_eor+1
                sta $dd00
fastload_receivebyte:
                lda $dd00
                lsr
                lsr
                eor $dd00
                lsr
                lsr
                eor $dd00
                lsr
                lsr
                eor $dd00
                cli
fastload_eor:   eor #$00
                sta loadbuffer,x
                inx
                bne fastload_fbloop

                else

                if (loadbuffer & $ff) != 0
                    err
                endif

                pha                       ;Some delay before beginning
                pla
                pha
                pla
                nop
fastload_fillbufferloop:                  ;1bit receive code
                nop
                nop
                ldx #$08                  ;Bit counter
fastload_bitloop:
                nop
                lda #$10
                eor $dd00                 ;Take databit
                sta $dd00                 ;Store reversed clockbit
                asl
fastload_store: ror loadbuffer
                dex
                bne fastload_bitloop
                if BORDER_FLASHING > 0
                dec $d020
                inc $d020
                endif
                inc fastload_store+1
                bne fastload_fillbufferloop

                endif

fillbuffer_common:
                lda #$02                        ;Reset buffer read pos.
                sta bufferstatus
                ldx #$ff
                lda loadbuffer                  ;Full 254 bytes?
                bne fastload_fullbuffer
                ldx loadbuffer+1                ;End of load?
                bne fastload_noloadend
                stx fileopen                    ;Clear fileopen indicator
                lda loadbuffer+2                ;Read the return/error code
                sta fileclosed+1
fastload_noloadend:
fastload_fullbuffer:
                stx fastload_endcmp+1
                pla
                clc
                bcc getbyte_restx

fileclosed:     lda #$00
                sec
                bcs getbyte_restx

;-------------------------------------------------------------------------------
; GETBYTE
;
; Gets a byte from an opened file.
;
; Parameters: -
; Returns: C=0 OK, A contains byte
;          C=1 File stream ended. A contains the error code:
;              $00 - OK, end of file
;              $02 - File not found
; Modifies: A
;-------------------------------------------------------------------------------

getbyte:        stx getbyte_restx+1
getbyte_usefastload:
                lda #$00
                beq slowload_getbyte
fastload_getbyte:
                ldx bufferstatus
                lda loadbuffer,x
fastload_endcmp:cpx #$00                       ;Reach end of buffer?
                bcs fastload_fillbuffer
                inc bufferstatus
getbyte_restx:  ldx #$00
                rts

slowload_getbyte:
                lda fileopen
                beq fileclosed
                jsr kernalon
                jsr chrin
                ldx status
                bne slowload_eof
                jsr kernaloff
                clc
                bcc getbyte_restx
slowload_eof:   pha
                txa
                and #$03
                sta fileclosed+1        ;EOF - store return code
                dec fileopen
                sty getbyte_resty+1
                jsr close_kernaloff
getbyte_resty:  ldy #$00
                pla
                ldx fileclosed+1        ;Check return code, if nonzero,
                cpx #$01                ;return with carry set and return
                bcc getbyte_restx       ;code in A
                txa
                bcs getbyte_restx

                if LOAD_UNDER_IO > 0
;-------------------------------------------------------------------------------
; DISABLEIO
;
; Stores $01 status, disables interrupts & IO area.
;
; Parameters: -
; Returns: -
; Modifies: -
;-------------------------------------------------------------------------------

disableio:      pha
                lda $01
                sta enableio_01+1
                lda #$34
                sei
                sta $01
                pla
                rts

;-------------------------------------------------------------------------------
; ENABLEIO
;
; Restores $01 status and enables interrupts.
;
; Parameters: -
; Returns: -
; Modifies: -
;-------------------------------------------------------------------------------

enableio:       pha
enableio_01:    lda #$36
                sta $01
                cli
                pla
                rts
                endif

;-------------------------------------------------------------------------------
; SETLFSDEVICE
;
; Gets the last used device number and performs a SETLFS.
;
; Parameters: -
; Returns: -
; Modifies: X
;-------------------------------------------------------------------------------

setlfsdevice:   ldx fa
                jmp setlfs

;-------------------------------------------------------------------------------
; KERNALON
;
; Switches KERNAL on to prepare for slow loading. Saves state of $01.
;
; Parameters: -
; Returns: -
; Modifies: X
;-------------------------------------------------------------------------------

kernalon:       ldx $01
                stx kernaloff+1
                ldx #$36
                stx $01
                rts

;-------------------------------------------------------------------------------
; CLOSE_KERNALOFF
;
; Closes file 2 and then restores state of $01.
;
; Parameters: -
; Returns: -
; Modifies: A,X,Y
;-------------------------------------------------------------------------------

close_kernaloff:lda #$02
                jsr close
                jsr clrchn

;-------------------------------------------------------------------------------
; KERNALOFF
;
; Restores state of $01.
;
; Parameters: -
; Returns: -
; Modifies: X
;-------------------------------------------------------------------------------

kernaloff:      ldx #$36
                stx $01
il_ok:          rts

;-------------------------------------------------------------------------------
; INITFASTLOAD
;
; Uploads the fastloader to disk drive memory and starts it.
;
; Parameters: -
; Returns: -
; Modifies: A,X,Y
;-------------------------------------------------------------------------------

initfastload:   lda usefastload         ;If fastloader not needed, do nothing
                beq il_ok
                lda fastloadstatus      ;If fastloader already initted,
                bne il_ok               ;do nothing
                inc fastloadstatus
                lda #<drivecode
                ldx #>drivecode
                ldy #(drvend-drvstart+MW_LENGTH-1)/MW_LENGTH

ifl_begin:      sta ifl_senddata+1
                stx ifl_senddata+2
                sty loadtempreg         ;Number of "packets" to send
                jsr kernalon
                lda #>drvstart
                sta ifl_mwstring+1
                ldy #$00
                sty ifl_mwstring+2      ;Drivecode starts at lowbyte 0
                beq ifl_nextpacket
ifl_sendmw:     lda ifl_mwstring,x      ;Send M-W command (backwards)
                jsr ciout
                dex
                bpl ifl_sendmw
                ldx #MW_LENGTH
ifl_senddata:   lda drivecode,y         ;Send one byte of drivecode
                jsr ciout
                iny
                bne ifl_notover
                inc ifl_senddata+2
ifl_notover:    inc ifl_mwstring+2      ;Also, move the M-W pointer forward
                bne ifl_notover2
                inc ifl_mwstring+1
ifl_notover2:   dex
                bne ifl_senddata
                jsr unlsn               ;Unlisten to perform the command
ifl_nextpacket: lda fa                  ;Set drive to listen
                jsr listen
                lda status
                cmp #$c0
                beq ifl_error           ;Abort if serial error (IDE64!)
                lda #$6f
                jsr second
                ldx #$05
                dec loadtempreg         ;All "packets" sent?
                bpl ifl_sendmw
ifl_sendme:     lda ifl_mestring-1,x    ;Send M-E command (backwards)
                jsr ciout
                dex
                bne ifl_sendme
                jsr unlsn
ifl_error:      jmp kernaloff

;-------------------------------------------------------------------------------
; DRIVECODE - Code executed in the disk drive.
;-------------------------------------------------------------------------------

drivecode:                              ;Address in C64's memory
                rorg drvstart           ;Address in diskdrive's memory

drvmain:        if TWOBIT_PROTOCOL > 0
                jsr drv_initsendtbl     ;One-time init for 2MHz send
                endif
                cli                     ;File loop: Get filename first
                lda #$00                ;Set DATA & CLK high
drv_1800ac0:    sta $1800
                if LONG_NAMES > 0
                ldx #$00
                else
                ldx #$01
                endif
drv_nameloop:   ldy #$08                ;Bit counter
drv_namebitloop:
drv_1800ac1:    lda $1800
                bpl drv_noquit          ;Quit if ATN is low
                jmp drv_quit
drv_noquit:     and #$05                ;Wait for CLK or DATA going low
                beq drv_namebitloop
                lsr                     ;Read the data bit
                lda #$02                ;Pull the other line low to acknowledge
                bcc drv_namezero ;the bit being received
                lda #$08
drv_namezero:   ror drv_filename,x      ;Store the data bit
drv_1800ac2:    sta $1800
drv_namewait:
drv_1800ac3:    lda $1800               ;Wait for either line going high
                and #$05
                cmp #$05
                beq drv_namewait
                lda #$00
drv_1800ac4:    sta $1800               ;Set both lines high
                dey
                bne drv_namebitloop     ;Loop until all bits have been received
                sei                     ;Disable interrupts after first byte
                if LONG_NAMES > 0
                inx
                lda drv_filename-1,x    ;End of filename?
                bne drv_nameloop
                else
                dex
                bpl drv_nameloop
                endif

                lda #$08                ;CLK low, data isn't available
drv_1800ac5:    sta $1800

drv_dirtrk:     ldx $1000
drv_dirsct:     ldy $1000               ;Read disk directory
drv_dirloop:    jsr drv_readsector      ;Read sector
                ldy #$02
drv_nextfile:   lda buf,y               ;File type must be PRG
                and #$83
                cmp #$82
                bne drv_notfound
                if LONG_NAMES > 0
                ldx #$03
                sty drv_namelda+1
                lda #$a0                ;Make an endmark at the 16th letter
                sta buf+19,y
drv_namecmploop:lda drv_filename-3,x    ;Check for wildcard first
                cmp #$2a
                beq drv_found
drv_namelda:    lda buf,x               ;Check against each letter of filename,
                cmp drv_filename-3,x    ;break on mismatch
                bne drv_namedone
                inx
                bne drv_namecmploop
drv_namedone:   cmp #$a0                ;If got endmark in both filenames, found
                bne drv_notfound
                lda drv_filename-3,x
                beq drv_found
                else
                lda buf+3,y
                cmp drv_filename
                bne drv_notfound
                lda buf+4,y
                cmp drv_filename+1
                beq drv_found
                endif
drv_notfound:   tya
                clc
                adc #$20
                tay
                bcc drv_nextfile
                ldy buf+1               ;Go to next directory block, go on until no
                ldx buf                 ;more directory blocks
                bne drv_dirloop
drv_filenotfound:
                ldx #$02                ;Return code $02 = File not found
drv_loadend:    stx buf+2
                lda #$00
                sta buf
                sta buf+1
                beq drv_sendblk

drv_quit:                               ;If ATN, exit to drive ROM code
drv_drivetype:  ldx #$00
                bne drv_quitnot1541
                lda #$1a                ;Restore data direction register
                sta $1802
                jmp initialize
drv_quitnot1541:rts

drv_found:      iny
drv_nextsect:   ldx buf,y       ;File found, get starting track & sector
                beq drv_loadend ;At file's end? (return code $00 = OK)
                lda buf+1,y
                tay
                jsr drv_readsector      ;Read the data sector

                if TWOBIT_PROTOCOL > 0

drv_sendblk:
drv_sendloop:
drv_2mhzsend:   lda buf
                ldx #$00                        ;Set CLK=high to mark data available
drv_1800ac6:    stx $1800
                tay
                and #$0f
                tax
                lda #$04                        ;Wait for CLK=low
drv_1800ac7:    bit $1800
                beq drv_1800ac7
                lda drv_sendtbl,x
                nop
                nop
drv_1800ac8:    sta $1800
                asl
                and #$0f
                cmp ($00,x)
                nop
drv_1800ac9:    sta $1800
                lda drv_sendtblhigh,y
                cmp ($00,x)
                nop
drv_1800ac10:   sta $1800
                asl
                and #$0f
                cmp ($00,x)
                nop
drv_1800ac11:   sta $1800
                inc drv_2mhzsend+1
                bne drv_2mhzsend
                nop
drv_2mhzsenddone:
                lda #$08                ;CLK low, data isn't available
drv_1800ac12:   sta $1800
                ldy #$00
                
                else

drv_sendblk:    lda #$04                ;Bitpair counter/
                ldx #$00                ;compare-value for CLK-line
drv_1800ac6:    stx $1800               ;CLK & DATA high -> ready to go
drv_sendloop:   ldx buf
drv_zpac1:      stx drvtemp
                tay                     ;Bitpair counter
drv_sendloop_bitpair:
                ldx #$00
drv_zpac2:      lsr drvtemp
                bcs drv_sendloop_wait1
                ldx #$02
drv_sendloop_wait1:
drv_1800ac7:    bit $1800               ;Wait until CLK high
                bne drv_sendloop_wait1
drv_1800ac8:    stx $1800
                ldx #$00
drv_zpac3:      lsr drvtemp
                bcs drv_sendloop_wait2
                ldx #$02
drv_sendloop_wait2:
drv_1800ac9:    bit $1800
                beq drv_sendloop_wait2  ;Wait until CLK low
drv_1800ac10:   stx $1800
                dey
                bne drv_sendloop_bitpair
                inc drv_sendloop+1
                bne drv_sendloop
drv_sendloop_endwait:
drv_1800ac11:   bit $1800               ;Wait for CLK high
                bne drv_sendloop_endwait
                asl                     ;Set CLK low, DATA high
drv_1800ac12:   sta $1800               ;(more data yet not ready)

                endif

                lda buf                 ;First 2 bytes zero marks end of loading
                ora buf+1               ;(3rd byte is the return code)
                bne drv_nextsect
                jmp drvmain

drv_readsector: jsr drv_led
drv_readtrk:    stx $1000
drv_readsct:    sty $1000
drv_retry:      lda #$80
                ldx #1
drv_execjsr:    jsr drv_1541exec        ;Exec buffer 1 job
                cmp #$02                ;Error?
                bcs drv_retry           ;Retry indefinitely
drv_success:    sei                     ;Make sure interrupts now disabled
drv_led:        lda #$08                ;Flash the drive LED
drv_ledac1:     eor $1c00
drv_ledac2:     sta $1c00
                rts

drv_1541exec:   sta $01
                cli                     ;Allow interrupts & execute command
drv_1541execwait:
                lda $01
                bmi drv_1541execwait
                pha
                lda id                  ;Handle disk ID change
                sta iddrv0
                lda id+1
                sta iddrv0+1
                pla
                rts

drv_fdexec:     jsr $ff54               ;FD2000 fix by Ninja
                lda $03
                rts

                if TWOBIT_PROTOCOL > 0

drv_initsendtbl:lda drv_drivetype+1     ;1541?
                bne drv_not1541
                lda $e5c6
                cmp #$37
                bne drv_not1571         ;Enable 2Mhz mode on 1571
                jsr $904e
drv_not1571:    lda #$7a                ;Set data direction so that can compare against $1800 being zero
                sta $1802
drv_not1541:    ldx #$00
drv_sendtblloop:txa                     ;Build high nybble send table
                lsr
                lsr
                lsr
                lsr
                tay
                lda drv_sendtbl,y
                sta drv_sendtblhigh,x
                inx
                bne drv_sendtblloop
                rts

drv_sendtbl:    dc.b $0f,$07,$0d,$05
                dc.b $0b,$03,$09,$01
                dc.b $0e,$06,$0c,$04
                dc.b $0a,$02,$08,$00
                endif

drv_1541dirtrk: dc.b 18
drv_1541dirsct: dc.b 1
drv_1581dirsct: dc.b 3
drv_filename:

drvend:
                if drvend > drv_sendtblhigh
                    err
                endif

                rend

;-------------------------------------------------------------------------------
; M-W and M-E command strings
;-------------------------------------------------------------------------------

ifl_mwstring:   dc.b MW_LENGTH,$00,$00,"W-M"

ifl_mestring:   dc.b >drvstart, <drvstart, "E-M"

;-------------------------------------------------------------------------------
; Filename (in short name mode)
;-------------------------------------------------------------------------------

                if LONG_NAMES=0
filename:       dc.b "00*"
                endif

;-------------------------------------------------------------------------------
; Loader configuration
;-------------------------------------------------------------------------------

usefastload:    dc.b 0                          ;If nonzero, fastloading will
                                                ;be used (autoconfigured)
useserial:      dc.b 1                          ;If nonzero, serial protocol
                                                ;is in use and IRQs can't be
                                                ;used reliably while Kernal
                                                ;file I/O is in progress

;-------------------------------------------------------------------------------
; Disposable portion of loader (routines only needed when initializing)
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; INITLOADER
;
; Inits the loadersystem. Must only be called only once in the beginning.
;
; Parameters: -
; Returns: -
; Modifies: A,X,Y
;-------------------------------------------------------------------------------

initloader:     sta $d07f                       ;Disable SCPU hardware regs
                lda #$00
                sta messages                    ;Disable KERNAL messages
                sta fastloadstatus              ;Initial fastload status = off
                sta fileopen                    ;No file initially open

                if TWOBIT_PROTOCOL>0
                sei
                tax
il_detectntsc1: lda $d012                       ;Detect PAL/NTSC/Drean
il_detectntsc2: cmp $d012
                beq il_detectntsc2
                bmi il_detectntsc1
                cmp #$20
                bcc il_isntsc
il_countcycles: inx
                lda $d012
                cmp #$28
                bcc il_countcycles
                cpx #$e8
                bcc il_ispal
                bcs il_isdrean
il_isntsc:
il_isdrean:     lda #$25                        ;Adjust 2-bit fastload transfer delay for NTSC / Drean
                sta fastload_delay
                lda #loadtempreg
                sta fastload_delay+1
il_ispal:       cli
                endif

il_detectdrive: lda #$aa
                sta $a5
                lda #<il_drivecode
                ldx #>il_drivecode
                ldy #(il_driveend-il_drivecode+MW_LENGTH-1)/MW_LENGTH
                jsr ifl_begin                   ;Upload test-drivecode
                lda status                      ;If serial error here, not a
                cmp #$c0                        ;serial device
                beq il_noserial
                ldx #$00
                ldy #$00
il_delay:       inx                             ;Delay to make sure the test-
                bne il_delay                    ;drivecode executed to the end
                iny
                bpl il_delay
                lda fa                          ;Set drive to listen
                jsr listen
                lda #$6f
                jsr second
                ldx #$05
il_ddsendmr:    lda il_mrstring,x               ;Send M-R command (backwards)
                jsr ciout
                dex
                bpl il_ddsendmr
                jsr unlsn
                lda fa
                jsr talk
                lda #$6f
                jsr tksa
                lda #$00
                jsr acptr                       ;First byte: test value
                pha
                jsr acptr                       ;Second byte: drive type
                tax
                jsr untlk
                pla
                cmp #$aa                        ;Drive can execute code, so can
                beq il_fastloadok               ;use fastloader
                lda $a5                         ;If serial bus delay counter
                cmp #$aa                        ;untouched, not a serial device
                bne il_nofastload
il_noserial:    dec useserial                   ;Serial bus not used: switch to
il_nofastload:  rts                             ;"fake" IRQ-loading mode

il_fastloadok:  sta usefastload                 ;Perform patching of drivecode according to detected type
                sta getbyte_usefastload+1
                if TWOBIT_PROTOCOL > 0
                txa                             ;For 1541, need to copy the 1MHz transfer code
                bpl il_not1571                  ;$ff = 1571, turn to $00 (1541)
                inx
                beq il_2mhzdrive
il_not1571:     bne il_2mhzdrive
                ldy #drv_1mhzsenddone-drv_1mhzsend-1
il_copy1mhzcode:lda il_drv1mhzsend,y
                sta drv_2mhzsend-drvstart+drivecode,y
                dey
                bpl il_copy1mhzcode
il_2mhzdrive:   endif
                stx il_drivetype+1
                stx drv_drivetype+1-drvstart+drivecode
                txa
                beq il_skippatch1800            ;$1800 patching not needed for 1541
                lda il_1800lo-1,x               ;Perform patching of drivecode
                sta il_patch1800lo+1
                lda il_1800hi-1,x
                sta il_patch1800hi+1
                ldy #12
il_patchloop:   ldx il_1800ofs,y
il_patch1800lo: lda #$00                        ;Patch all $1800 accesses
                sta drvmain+1-drvstart+drivecode,x
il_patch1800hi: lda #$00
                sta drvmain+2-drvstart+drivecode,x
                dey
                bpl il_patchloop
il_skippatch1800:
il_drivetype:   ldx #$00
                lda il_dirtrklo,x               ;Patch directory
                sta drv_dirtrk+1-drvstart+drivecode
                lda il_dirtrkhi,x
                sta drv_dirtrk+2-drvstart+drivecode
                lda il_dirsctlo,x
                sta drv_dirsct+1-drvstart+drivecode
                lda il_dirscthi,x
                sta drv_dirsct+2-drvstart+drivecode
                lda il_execlo,x                 ;Patch job exec address
                sta drv_execjsr+1-drvstart+drivecode
                lda il_exechi,x
                sta drv_execjsr+2-drvstart+drivecode
                lda il_jobtrklo,x               ;Patch job track/sector
                sta drv_readtrk+1-drvstart+drivecode
                clc
                adc #$01
                sta drv_readsct+1-drvstart+drivecode
                lda il_jobtrkhi,x
                sta drv_readtrk+2-drvstart+drivecode
                adc #$00
                sta drv_readsct+2-drvstart+drivecode    
                if TWOBIT_PROTOCOL=0
                lda il_zp,x                     ;Patch zeropage temp usage
                sta drv_zpac1+1-drvstart+drivecode
                sta drv_zpac2+1-drvstart+drivecode
                sta drv_zpac3+1-drvstart+drivecode
                endif
                lda il_ledenabled,x             ;Patch LED flashing
                sta drv_led-drvstart+drivecode
                lda il_ledbit,x
                sta drv_led+1-drvstart+drivecode
                lda il_ledadrhi,x
                sta drv_ledac1+2-drvstart+drivecode
                sta drv_ledac2+2-drvstart+drivecode
                rts

;-------------------------------------------------------------------------------
; IL_DRIVECODE - Drivecode used to detect drive type & test if drivecode
; execution works OK
;-------------------------------------------------------------------------------

il_drivecode:
                rorg drvstart

                asl ild_return1         ;Modify first returnvalue to prove
                                        ;we've executed something :)
                lda $fea0               ;Recognize drive family
                ldx #3                  ;(from Dreamload)
ild_floop:      cmp ild_family-1,x
                beq ild_ffound
                dex                     ;If unrecognized, assume 1541
                bne ild_floop
                beq ild_1541
ild_ffound:     lda ild_idloclo-1,x
                sta ild_idlda+1
                lda ild_idlochi-1,x
                sta ild_idlda+2
ild_idlda:      lda $fea4               ;Recognize drive type
                ldx #3                  ;3 = CMD HD
ild_idloop:     cmp ild_id-1,x          ;2 = CMD FD
                beq ild_idfound         ;1 = 1581
                dex                     ;0 = 1541
                bne ild_idloop
ild_1541:       if TWOBIT_PROTOCOL > 0
                lda $e5c6
                cmp #$37
                bne ild_idfound         ;Recognize 1571 as a subtype
                dex                     ;$ff = 1571
                endif
ild_idfound:    stx ild_return2
                rts

ild_family:     dc.b $43,$0d,$ff
ild_idloclo:    dc.b $a4,$c6,$e9
ild_idlochi:    dc.b $fe,$e5,$a6
ild_id:         dc.b "8","F","H"

ild_return1:    dc.b $55
ild_return2:    dc.b 0

                rend

il_driveend:

;-------------------------------------------------------------------------------
; IL_DRV1MHZSEND - 2-bit protocol send code for 1MHz drives
;-------------------------------------------------------------------------------

                if TWOBIT_PROTOCOL > 0
il_drv1mhzsend:
                rorg drv_2mhzsend

drv_1mhzsend:   ldx #$00
drv_1mhzsendloop:
                lda buf
                tay
                and #$0f
                stx $1800
                tax
                lda drv_sendtbl,x
drv_1mhzwait:   ldx $1800
                beq drv_1mhzwait
                sta $1800
                asl
                and #$0f
                sta $1800
                lda drv_sendtblhigh,y
                sta $1800
                asl
                and #$0f
                sta $1800
                inc drv_1mhzsendloop+1
                bne drv_1mhzsendloop
                beq drv_2mhzsenddone
drv_1mhzsenddone:
                rend
                endif

il_mrstring:    dc.b 2,>ild_return1,<ild_return1,"R-M"

il_1800ofs:     dc.b drv_1800ac0-drvmain
                dc.b drv_1800ac1-drvmain
                dc.b drv_1800ac2-drvmain
                dc.b drv_1800ac3-drvmain
                dc.b drv_1800ac4-drvmain
                dc.b drv_1800ac5-drvmain
                dc.b drv_1800ac6-drvmain
                dc.b drv_1800ac7-drvmain
                dc.b drv_1800ac8-drvmain
                dc.b drv_1800ac9-drvmain
                dc.b drv_1800ac10-drvmain
                dc.b drv_1800ac11-drvmain
                dc.b drv_1800ac12-drvmain

il_1800lo:      dc.b <$4001,<$4001,<$8000
il_1800hi:      dc.b >$4001,>$4001,>$8000

il_dirtrklo:    dc.b <drv_1541dirtrk,<$022b,<$54,<$2ba7
il_dirtrkhi:    dc.b >drv_1541dirtrk,>$022b,>$54,>$2ba7
il_dirsctlo:    dc.b <drv_1541dirsct,<drv_1581dirsct,<$56,<$2ba9
il_dirscthi:    dc.b >drv_1541dirsct,>drv_1581dirsct,>$56,>$2ba9

il_execlo:      dc.b <drv_1541exec,<$ff54,<drv_fdexec,<$ff4e
il_exechi:      dc.b >drv_1541exec,>$ff54,>drv_fdexec,>$ff4e

il_jobtrklo:    dc.b <$0008,<$000d,<$000d,<$2802
il_jobtrkhi:    dc.b >$0008,>$000d,>$000d,>$2802

                if TWOBIT_PROTOCOL=0
il_zp:          dc.b $06,$0b,$0b,$06
                endif

il_ledenabled:  dc.b $a9,$a9,$a9,$60
il_ledbit:      dc.b $08,$40,$40,$00
il_ledadrhi:    dc.b $1c,$40,$40,$40
