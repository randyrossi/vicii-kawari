                processor 6502
		org 0500

RETRIES         = 5             ;Amount of retries when reading a sector
acsbf           = $01           ;Buffer 1 command
trkbf           = $08           ;Buffer 1 track
sctbf           = $09           ;Buffer 1 sector
iddrv0          = $12           ;Disk drive ID
id              = $16           ;Disk ID
datbf           = $14           ;Temp variable
buf             = $0400         ;Sector data buffer

                rorg $0500
drive:          
                cli             ;Enable interrupts while waiting the first byte
                jsr getbyte     ;(to allow motor to stop)
                sta namecmp2+1
                sei             ;Disable while waiting second byte
                jsr getbyte
                sta namecmp1+1
                lda #$08        ;Set CLK=low to tell C64 there's no data to
                sta $1800       ;be read yet
                ldx #18
                ldy #1	        ;Read disk directory
dirloop:        stx trkbf
                sty sctbf
                jsr readsect    ;Read sector
                bcc error       ;If failed, return error code
                ldy #$02
nextfile:       lda buf,y       ;File type must be PRG
                and #$83
                cmp #$82
                bne notfound
                lda buf+3,y     ;Check first letter
namecmp1:       cmp #$00
                bne notfound
                lda buf+4,y     ;Check second letter
namecmp2:       cmp #$00
                beq found
notfound:       tya
                clc
                adc #$20
                tay
                bcc nextfile
                ldy buf+1       ;Go to next directory block, go on until no
                ldx buf	        ;more directory blocks
                bne dirloop
error:          lda #$01        ;Send $01 - error in loading file
loadend:        jsr sendbyte
                lda $1800       ;Set CLK=High
                and #$f7
                sta $1800
                lda #$04
loadend_wait:   bit $1800       ;Wait for CLK=High
                bne loadend_wait
                ldy #$00        ;Set DATA=High
                sty $1800
                jmp drive       ;Go back to wait for the filename

found:          iny
nextsect:       lda buf,y       ;File found, get starting track & sector
                sta trkbf
                beq loadend     ;If at file's end, send byte $00
                lda buf+1,y
                sta sctbf
                jsr readsect    ;Read the data sector
                bcc error
                ldy #$ff        ;Amount of bytes to send - assume $ff
                lda buf
                bne sendblk
                ldy buf+1       ;Possibly less if it's the last block
sendblk:        tya
sendloop:       jsr sendbyte    ;Send the amount of bytes that will be sent
                lda buf,y       ;Send the sector data in reverse order
                dey
                bne sendloop
                beq nextsect

readsect:       ldy #RETRIES    ;Retry counter
retry:          cli             ;Enable interrupts so that command can be
                jsr success     ;executed, turn on led
                lda #$80
                sta acsbf       ;Command:read sector
poll1:          lda acsbf       ;Wait until ready
                bmi poll1
                sei
                cmp #1
                beq success     ;Also sets carry flag to 1
                lda id	        ;Check for disk ID change
                sta iddrv0
                lda id+1
                sta iddrv0+1
                dey             ;Decrease retry counter
                bne retry
failure:        clc
success:        lda $1c00
                eor #$08
                sta $1c00
                rts

sendbyte:       sta datbf       ;Store the byte to a temp variable
                tya             ;Store Y-register contents
                pha
                ldy #$04
                lda $1800
                and #$f7
                sta $1800
                tya
s1:             asl datbf       ;Rotate bit to carry and "invert"
                ldx #$02
                bcc s2
                ldx #$00
s2:             bit $1800
                bne s2
                stx $1800
                asl datbf
                ldx #$02
                bcc s3
                ldx #$00
s3:             bit $1800
                beq s3
                stx $1800
                dey
                bne s1
                txa
                ora #$08
                sta $1800
                pla
                tay
                rts

getbyte:        ldy #8	        ;Counter: receive 8 bits
recvbit:
                lda #$85
                and $1800	;Wait for CLK==low || DATA==low
                bmi gotatn	;Quit if ATN was asserted
                beq recvbit
                lsr		;Read the data bit
                lda #2	        ;Prepare for CLK=high, DATA=low
                bcc rskip
                lda #8	        ;Prepare for CLK=low, DATA=high
rskip:          sta $1800	;Acknowledge the bit received
                ror datbf	;and store it
rwait:          lda $1800	;Wait for CLK==high || DATA==high
                and #5
                eor #5
                beq rwait
                lda #0
                sta $1800	;Set CLK=DATA=high
                dey
                bne recvbit	;Loop until all bits have been received
                lda datbf	;Return the data to A
                rts
gotatn:         pla		;If ATN gets asserted, exit to the operating
                pla		;system. Discard the return address.
                rend
il_ok:          rts

