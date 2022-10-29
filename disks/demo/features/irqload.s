SIDInit   = $1000
SIDUpdate = $1003

;status          = $90           ;Kernal zeropage variables
;messages        = $9d
fa              = $ba

;The loader itself uses two zeropage variables. 

;temp1           = $02           ;Temporary zeropage variables
;temp2           = $03
temp1           = $fb           ;Temporary zeropage variables
temp2           = $fc

;Then the KERNAL routine defines. There's a lot of unused ones but it doesn't
;hurt.

ciout           = $ffa8         ;Kernal routines
listen          = $ffb1
second          = $ff93
unlsn           = $ffae
acptr           = $ffa5
chkin           = $ffc6
chkout          = $ffc9
chrin           = $ffcf
chrout          = $ffd2
ciout           = $ffa8
close           = $ffc3
open            = $ffc0
setmsg          = $ff90
setnam          = $ffbd
setlfs          = $ffba
clrchn          = $ffcc
getin           = $ffe4
load            = $ffd5
save            = $ffd8

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


;Here comes the main program. Basically it initializes the fastloader,
;initializes raster interrupts to play music located at $1000 while loading
;(Eighties Megahit by Olli Niemitalo), performs the actual loading subroutine
;call, then de-initializes raster interrupts and exits.

                processor 6502
                org 2049


;Example main program. Inits the fastloader and loads a file using it. After-
;wards the drive can be used normally.

; jump past vectors and stuff
sys:            dc.b $0b,$08           ;Address of next instruction
                dc.b $0a,$00           ;Line number(10)
                dc.b $9e               ;SYS-token
                dc.b $32,$30,$37,$31   ;2071 as ASCII
                dc.b $00
                dc.b $00,$00           ;Instruction address 0 terminates
                                       ;the basic program

; Put this stuff here so our segments can call these
; if needed
vectors:        jmp initmusicplayback  ; $80d
                jmp fastload           ; $810
                jmp install_colors     ; $813
                ; Set this to 1 to write to Kawari port A
                ; instead of DRAM. Get the location from dasm
                ; output
directVmem:     dc.b 0   ; $816

start:          

                ; load cc64 compiled demo section
		ldx #<segment1
		ldy #>segment1
                lda #2 ; length of fname
		jsr loader

                ; have to do this early before we call into
                ; demo intro
                jsr initfastload

                ; show demo intro
                ; load addr was 40a0 but we need to skip past the
                ; basic load pgm and jump straight into it ourselves
                jsr $40ad

                lda #0
                sta directVmem

                ; kawari inside logo
                ldx #"S"
                ldy #"2"
                jsr fastload
                jsr $40ad

                ; configurable palette demo
                ldx #"S"
                ldy #"3"
                jsr fastload
                jsr $40ad

                ; 80 column demo
                ldx #"S"
                ldy #"4"
                jsr fastload
                jsr $40ad

                ; TODO - MOVE THIS INTO REAL SEGMENTS

                ; S5 = bruno_img.bin
                ; load next img direct to vmem
                lda #1
                sta directVmem
                lda #0
                sta $d035 ; zero out idx
                lda #1
                sta $d03f ; vmem with auto inc
                ldx #"S"
                ldy #"5"
                jsr fastload

                ; S6 = bruno_col.bin
                lda #0
                sta directVmem
                ldx #"S"
                ldy #"6"
                jsr fastload
                jsr install_colors
                
                ; Turn on hires 320x200 
                lda #16+64
                sta KAWARI_VMODE1
                lda #0
                STA KAWARI_VMODE2

                ; short description
                ldx #"S"
                ldy #"7"
                jsr fastload
                jsr $40ad
                
                ; S8 = horse_img.bin
                ; load next img direct to vmem
                lda #1
                sta directVmem
                lda #0
                sta $d035 ; zero out idx
                lda #1
                sta $d03f ; vmem with auto inc
                ldx #"S"
                ldy #"8"
                jsr fastload

                ; S9 = horse_col.bin
                lda #0
                sta directVmem
                ldx #"S"
                ldy #"9"
                jsr fastload
                jsr install_colors
                
                ; Turn on hires 640x200 
                lda #16+64+32
                sta KAWARI_VMODE1
                lda #0
                STA KAWARI_VMODE2

                ; END TODO - MOVE THIS INTO REAL SEGMENTS

                ; segment 10 - falcon
                ldx #"S"
                ldy #"A"
                jsr fastload
                jsr $40ad

                ; segment 11 - removed

                ; segment 12 - mandelbrot
                ldx #"S"
                ldy #"C"
                jsr fastload
                jsr $40ad

                ; segment 13 - blitter
                ldx #"S"
                ldy #"D"
                jsr fastload
                jsr $40ad

forever:
		inc $d020
                jmp forever

initmusicplayback:
                sei
                lda #<raster
                sta $0314
                lda #>raster
                sta $0315
                lda #50                         ;Set low bits of raster
                sta $d012                       ;position
                lda $d011
                and #$7f                        ;Set high bit of raster
                sta $d011                       ;position (0)
                lda #$7f                        ;Set timer interrupt off
                sta $dc0d
                lda #$01                        ;Set raster interrupt on
                sta $d01a
                lda $dc0d                       ;Acknowledge timer interrupt
                lda #$00

                lda #0
                jsr SIDInit

                cli
                rts

stopmusicplayback:
                sei
                lda #<$ea31
                sta $0314
                lda #>$ea31
                sta $0315
                lda #$00
                sta $d01a
                lda #$81
                sta $dc0d
                inc $d019
                lda #$00
                sta $d418
                cli
                rts

raster:         
                jsr SIDUpdate
                lda #$ff
                sta $d019 ; ack interrupt status
                jmp $ea31
/*
                pla
                tay
                pla
                tax
                pla
                rti
*/


;Here is the initialization routine, that "uploads" the custom code to the disk
;drive's memory (with the Memory-Write, M-W command, 32 bytes at a time) and
;once all code has been uploaded, starts it with the Memory Execute, M-E command.
;For giving commands, the drive must be set to listen, and an unlisten actually
;starts the execution of a command.

;INITFASTLOAD
;
;Uploads the fastloader to disk drive memory and starts it.
;This routine is completely Marko M�kel�'s work.
;
;Parameters: -
;Returns: -
;Modifies: A,X,Y


AMOUNT          = 32                    ;Bytes in one M-W command

initfastload:   lda #<drvprog           ;Initialize selfmodifying code
                sta il_mwbyte+1
                lda #>drvprog
                sta il_mwbyte+2
                lda #<drive
                sta mwcmd+2
                lda #>drive
                sta mwcmd+1
il_mwloop:      jsr il_device           ;Set drive to listen
                ldx #lmwcmd - 1
il_sendmw:      lda mwcmd,x             ;Send M-W command
                jsr ciout
                dex
                bpl il_sendmw
                ldx #0
il_mwbyte:      lda drvprog,x             ;Send AMOUNT bytes of drive
                jsr ciout                 ;code
                inx
                cpx #AMOUNT
                bne il_mwbyte
                jsr unlsn               ;Unlisten starts the command
                lda mwcmd+2
                clc
                adc #AMOUNT
                sta mwcmd+2
                bcc il_nohigh
                inc mwcmd+1
il_nohigh:      lda il_mwbyte+1
                clc                     ;Move pointers
                adc #AMOUNT
                sta il_mwbyte+1
                tax
                bcc il_nohigh2
                inc il_mwbyte+2
il_nohigh2:     lda il_mwbyte+2
                cpx #<drvprogend
                sbc #>drvprogend
                bcc il_mwloop

                jsr il_device           ;Set drive to listen again
                ldx #lmecmd - 1
il_sendme:      lda mecmd,x             ;Send M-E command
                jsr ciout
                dex
                bpl il_sendme
                jmp unlsn               ;Unlisten starts the command

il_device:      lda fa
                jsr listen
                lda #$6f
                jmp second

;And now the fast loading routine itself.

;FASTLOAD
;
;Loads a file with fastloader. INITFASTLOAD must have been called first.
;Any normal KERNAL disk operations will cause the fastloader drive code to
;exit (as ATN line goes low) and after that, INITFASTLOAD has to be called
;again.
;
;Parameters: X: First letter of filename, Y: Second letter of filename
;Returns: C=0 OK, C=1 error
;Modifies: A,X,Y

;We start by storing the filename (two first letters given in X & Y registers)

fastload:       stx filename
                sty filename+1

;Because the Drive->C64 data sending depends on the C64 not going too fast, we
;must initialize the slow mode of SuperCPU (for those who own it)

                sta $d07a               ;SCPU to slow mode

;Next we store the stackpointer, to allow the loader to exit from any number
;of nested subroutines.

                tsx                     ;Store stackpointer, needed when
                stx stackptrstore       ;finishing loading

;Then we send the two bytes of the filename to the diskdrive (the custom code
;uploaded is now running there). This byte sending protocol is Marko's invention
;and it's completely asynchronous (so it could be run with fast mode of SuperCPU
;and it would still work)

;For each bit we do the following:
;- First the C64 waits both CLK & DATA lines of the serial bus to go high.
;- If a 0-bit is to be sent, C64 pulls the CLK-line low
;- If a 1-bit is to be sent, C64 pulls the DATA-line low
;- Now C64 waits for the drive to respond by pulling the other line low
;- Then C64 puts both its CLK & DATA lines back high. We start from the
;  beginning again...

                ldx #$01                ;Byte counter.
fastload_sendouter:
                ldy #$08                ;Bit counter
fastload_sendinner:
                bit $dd00               ;Wait for CLK & DATA high
                bvc fastload_sendinner
                bpl fastload_sendinner
                lsr filename,x          ;Rotate byte to be sent
                lda $dd00
                and #$ff-$30
                ora #$10
                bcc fastload_zerobit
                eor #$30
fastload_zerobit:
                sta $dd00
                lda #$c0                ;Wait for CLK & DATA low
fastload_sendack:
                bit $dd00
                bne fastload_sendack
                lda $dd00
                and #$ff-$30            ;Set DATA and CLK high
                sta $dd00
                dey
                bne fastload_sendinner
                dex                     ;All bytes sent?
                bpl fastload_sendouter

;Next is a small delay. This is to be sure that the disk drive has finished
;receiving the second byte of the filename, after which it pulls the CLK line
;low to signal that it's not ready yet to send a byte of the file data.

fastload_delay: dex                     ;Give the drive some time to set CLK
                bne fastload_delay      ;low in preparation to sending bytes

;We buffer a whole sector at a time from the disk. Mark the buffer to be
;"empty" now, as we're starting the loading.

                lda #$00                ;Initialize buffer counter
                sta temp2

;Get the first two bytes of the file, the startaddress.

                lda directVmem
                cmp #0
                bne useKawari
                jsr fastload_getbyte    ;Get file start address
                sta fastload_sta+1
                jsr fastload_getbyte
                sta fastload_sta+2

;Now loop, getting bytes and storing them to memory. The getbyte routine exits
;automatically when all bytes have been received.

fastload_loop:  jsr fastload_getbyte    ;Then get bytes one by one. Getbyte
fastload_sta:   sta $1000               ;routine exits when all have been
                inc $d020               ;received.
                dec $d020               ;Just some flashing to know we're
                inc fastload_sta+1      ;loading...
                bne fastload_loop
                inc fastload_sta+2
                jmp fastload_loop

; This sets up Kawari port A with the start address in VMEM
useKawari:      jsr fastload_getbyte    ;Get file start address
                sta 53305
                jsr fastload_getbyte
                sta 53306
                lda #$3b
                sta fastload_sta2+1
                lda #$d0
                sta fastload_sta2+2

; Goes direct to VMEM
fastload_loop2: jsr fastload_getbyte    ;Then get bytes one by one. Getbyte
fastload_sta2:  sta $1000               ;routine exits when all have been
                inc $d020               ;received.
                dec $d020               ;Just some flashing to know we're
                jmp fastload_loop2

;The getbyte subroutine. If there's bytes in the buffer, use them (in reverse
;order), until buffer is empty.

fastload_getbyte:
                ldx temp2                ;Bytes still in buffer?
                beq fastload_fillbuffer
                lda loadbuffer-1,x
                dex
                stx temp2
                rts

;Buffer is empty - we have to get bytes from the diskdrive. The diskdrive will
;first send a code to indicate amount of bytes to transfer, or an error code, or
;a "loading ended successfully" code. The codes the diskdrive will send are:

;$00 - Load ended
;$01 - File not found or sector read error
;$02-$ff - Amount of bytes to be transferred+1

fastload_fillbuffer:
                jsr fastload_get        ;Get number of bytes to transfer
                cmp #$01                ;$00 indicates successful end of load
                bcc fastload_loadend    ;and $01 an error
                beq fastload_loadend    ;Carry is set already (error sign)
                sbc #$01                ;Carry is 1 here
                sta temp2                ;Store buffer length to bytecounter
                ldx #$00

;Then we just loop to get all the bytes to the buffer. The 1541 will send the
;bytes from the end of the sector to the start (reverse order). Because we
;also use reverse order when getting the bytes from the buffer, this time
;we must use the normal order.

fastload_gnbloop:
                jsr fastload_get        ;Get the buffer byte by byte
                sta loadbuffer,x
                inx
                cpx temp2
                bcc fastload_gnbloop
                bcs fastload_getbyte

;When loading ends, get the stored stack pointer value, set SuperCPU back to
;fast mode and exit.

fastload_loadend:
                ldx stackptrstore       ;Restore stackpointer & exit loader
                txs
                sta $d07b               ;SCPU to fast mode
                rts

;The subroutine to get a byte from the diskdrive (by K.M/TABOO.) First we wait
;the drive to become ready, it signals this by letting CLK go high. At that
;point, it has also put the first databit on the DATA line (DATA is high for an
;1-bit and low for a 0-bit)

;We signal the drive to give the next databit by reversing the state of the
;CLK line (it becomes low now). There must be some delay to allow the drive
;to react (this is why the routine must not run too fast on the C64 side)
;and we continue this until all 8 bits have been received. The byte transfer
;ends by the drive pulling CLK back to low state.

fastload_get:   bit $dd00               ;Wait until 1541 is ready to send
                bvc fastload_get        ;(CLK=high)
                lda #$0f
                and $dd00
                sta $dd00
                nop
                ldy #$08                ;Bit counter
fastload_bitloop:
                nop
                nop
                lda #$10
                eor $dd00               ;Take databit from serialport and
                sta $dd00               ;store reversed clockbit
                asl
                rol temp1
                lda temp1
                dey
                bne fastload_bitloop    ;All bits done?
                rts

;The last part of the IRQ-loader is the drive code itself. Note the use of
;DASM's rorg directive to target code for the drive RAM at $0500.

;DRVPROG - Code executed in the disk drive.

RETRIES         = 5             ;Amount of retries when reading a sector
acsbf           = $01           ;Buffer 1 command
trkbf           = $08           ;Buffer 1 track
sctbf           = $09           ;Buffer 1 sector
iddrv0          = $12           ;Disk drive ID
id              = $16           ;Disk ID
datbf           = $14           ;Temp variable
buf             = $0400         ;Sector data buffer

drvprog:                        ;Address in C64's memory
                rorg $0500      ;Address in diskdrive's memory

;Code execution starts here. As the C64->drive transfer of the filename is
;asynchronous, interrupts don't matter. Interrupts are enabled to allow the
;disk motor to eventually stop after loading a file.

drive:          cli             ;Enable interrupts while waiting the first byte
                jsr getbyte     ;(to allow motor to stop)
                sta namecmp2+1

;After the 1st byte we forbid interrupts. That is because after receiving the
;second byte of the filename is done, the rest of the communication becomes
;timing-critical for the disk drive, and any unknown interruptions aren't
;allowed.

                sei             ;Disable while waiting second byte
                jsr getbyte
                sta namecmp1+1
                lda #$08        ;Set CLK=low to tell C64 there's no data to
                sta $1800       ;be read yet

;Next we read sector 1 from track 18 (the disk directory)

                ldx #18
                ldy #1	        ;Read disk directory
dirloop:        stx trkbf
                sty sctbf
                jsr readsect    ;Read sector
                bcc error       ;If failed, return error code
                ldy #$02
;
;Then we go through all filename entries on the first directory block. The file
;type must match that of a .PRG file and the two first letters of the filename
;are compared. If these are satisfied, we consider the file to be found...
;
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

;If not, move on to next filename entry on the directory block (each is 32
;bytes).

notfound:       tya
                clc
                adc #$20
                tay
                bcc nextfile

;After all names done, we read the next directory block, or give an error if
;that was the last directory block and file still not found.

                ldy buf+1       ;Go to next directory block, go on until no
                ldx buf	        ;more directory blocks
                bne dirloop
error:          lda #$01        ;Send $01 - error in loading file
loadend:        jsr sendbyte

;After the last byte has been sent, wait for CLK to become high to see that
;the C64 has read the last databit. After that, also the DATA line can be
;set high and we may start again from the beginning (waiting for the filename.)

                lda $1800       ;Set CLK=High
                and #$f7
                sta $1800
                lda #$04
loadend_wait:   bit $1800       ;Wait for CLK=High
                bne loadend_wait
                ldy #$00        ;Set DATA=High
                sty $1800
                jmp drive       ;Go back to wait for the filename

;The file has been found. Get its starting track and sector (the same code is
;reused for getting the next track§or link)

found:          iny
nextsect:       lda buf,y       ;File found, get starting track & sector
                sta trkbf
                beq loadend     ;If at file's end, send byte $00
                lda buf+1,y
                sta sctbf
                jsr readsect    ;Read the data sector
                bcc error

;If this isn't the last block of a file (link to next track nonzero), we will
;send the full 254 data bytes. Otherwise, the sector link byte contains the
;amount of bytes in the last block+1.

                ldy #$ff        ;Amount of bytes to send - assume $ff
                lda buf
                bne sendblk
                ldy buf+1       ;Possibly less if it's the last block
sendblk:        tya

;Here we loop to send all bytes of the block in reverse order.

sendloop:       jsr sendbyte    ;Send the amount of bytes that will be sent
                lda buf,y       ;Send the sector data in reverse order
                dey
                bne sendloop
                beq nextsect

;Sector read subroutine. Not much to say about this, it will retry 5 times
;before giving up and signaling error (carry set), otherwise it clears the carry
;to tell the sector was read OK. Note that the drive led will be toggled during
;the reading, and switched off afterwards.

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

;Send byte subroutine. First sets CLK high to signal a byte is ready, and puts
;the first databit on the DATA line (DATA is high when an 1-bit is being sent).
;Then it waits for the C64 to toggle the state of the CLK line before putting
;the next data bit online, until all bits have been sent. The routine ends with
;the drive pulling the CLK line back low. This routine is from K.M/TABOO.

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

;Receive byte subroutine by Marko M�kel�. If ATN is pulled low, exit the custom
;code, back to the drive's operating system ROM to allow normal operation.
;Otherwise, wait for either line to become low (CLK for a 0-bit, DATA for an
;1-bit). Then acknowledge the bit by pulling the other line low and wait for the
;C64 to release the line it had pulled low. Finally set both lines high and loop
;until all bits received.

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

drvprogend:

loader:
        jsr $FFBD ; SETNAM
        lda #4    ; logical num
        ldx #8
        ldy #1    ; secondary - 1=use location bytes, 0=don't
        jsr $FFBA ; SETLFS
        lda #0    ; LOAD = 0, VERIFY = 1
        ldx #$00  ; ignored
        ldy #$90  ; ignored
        jsr $FFD5 ; do LOAD
        rts

install_colors:
        lda #0
        sta VMEM_A_HI
        lda #64     ; color regs start at 64
        sta VMEM_A_LO
        lda #32
        sta KAWARI_PORT  ; make regs visible, no inc

        ; colors were loaded into $3000
        lda #$30
        sta $fc
        ldy #$00
        sty $fb

        ldy #0
loop3
        lda ($fb),y
        sta VMEM_A_VAL
        inc VMEM_A_LO
        iny
        tya
        cmp #64
        bne loop3

        lda #$a0     ; luma
        sta VMEM_A_LO
loop4
        lda ($fb),y
        sta VMEM_A_VAL
        inc VMEM_A_LO
        iny
        tya
        cmp #80
        bne loop4

        lda #$b0     ; phase
        sta VMEM_A_LO
loop5
        lda ($fb),y
        sta VMEM_A_VAL
        inc VMEM_A_LO
        iny
        tya
        cmp #96
        bne loop5

        lda #$c0     ; amp
        sta VMEM_A_LO
loop6
        lda ($fb),y
        sta VMEM_A_VAL
        inc VMEM_A_LO
        iny
        tya
        cmp #112
        bne loop6

        ; Something is hitting $d03f unexpectedly later on
        ; and if we leave VMEM_A_LO pointing to 0x80, it will
        ; kill the blanking level and composite will be garbage
        ; So set it to somthing harmless. TODO: Find this
        lda #0
        sta VMEM_A_LO
        lda #0
        sta KAWARI_PORT
        rts


;Here's the data for the M-W and M-E command strings, in reverse order.

mwcmd:          dc.b AMOUNT,>drive,<drive,"W-M"
lmwcmd          = . - mwcmd

mecmd:          dc.b >drive,<drive,"E-M"
lmecmd          = . - mecmd

;The stack pointer's initial
;value will be stored at the start of the load subroutine, so that the loader
;can exit from any number of nested subroutines.
stackptrstore:  dc.b 0


;The filename and sector buffer.
filename:       dc.b 0,0
segment1:       dc.b 83,49  ; S1
loadbuffer:     dc.b 254,0


;Music data.

                org $0f82
                incbin Lost_in_Space.sid
