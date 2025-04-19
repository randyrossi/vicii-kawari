r0   = $fb
r0L  = $fb
r0H  = $fc
r1   = $fd
r1L  = $fd
r1H  = $fe

RESLST               = $a09e
ERROR                = $a437
CUSTERROR            = $a445
NEWSTT               = $a7ae
EXECOLD              = $a7ed
CHAROUT              = $ab47
STROUT               = $ab1e
FRMNUM               = $ad8a
FRMEVL               = $ad9e
EVAL                 = $ae83
FUNCTOLD             = $ae8d
PARCHK               = $aef1
CHKCOM               = $aefd
FACINX               = $b1aa
ILLEGAL_QUANTITY     = $b248
FRESTR               = $b6a3
GETBYTC              = $b79b
GETADR               = $b7f7
OVERR                = $b97e
FINLOG               = $bd7e

ERROR_TOO_MANY_FILES         = $01
ERROR_FILE_OPEN              = $02
ERROR_FILE_NOT_OPEN          = $03
ERROR_FILE_NOT_FOUND         = $04
ERROR_DEVICE_NOT_PRESENT     = $05
ERROR_NOT_INPUT_FILE         = $06
ERROR_NOT_OUTPUT_FILE        = $07
ERROR_MISSING_FILENAME       = $08
ERROR_ILLEGAL_DEVICE_NUM     = $09
ERROR_NEXT_WITHOUT_FOR       = $0a
ERROR_SYNTAX                 = $0b
ERROR_RETURN_WITHOUT_GOSUB   = $0c
ERROR_OUT_OF_DATA            = $0d
ERROR_ILLEGAL_QUANTITY       = $0e
ERROR_OVERFLOW               = $0f
ERROR_OUT_OF_MEMORY          = $10
ERROR_UNDEFD_STATEMENT       = $11
ERROR_BAD_SUBSCRIPT          = $12
ERROR_REDIMD_ARRAY           = $13
ERROR_DIVISION_BY_ZERO       = $14
ERROR_ILLEGAL_DIRECT         = $15
ERROR_TYPE_MISMATCH          = $16
ERROR_STRING_TOO_LONG        = $17
ERROR_FILE_DATA              = $18
ERROR_FORMULA_TOO_COMPLEX    = $19
ERROR_CANT_CONTINUE          = $1a
ERROR_UNDEFD_FUNCTION        = $1b
ERROR_VERIFY                 = $1c
ERROR_LOAD                   = $1d


TR_BASDataReg         = $b2   ; (R/W) for TPUT/TGET data
TR_BASContReg         = $b4   ; (Write only) Control Reg
TR_BASStatReg         = $b6   ; (Read only) Status Reg
TR_BASFileNameReg     = $b8   ; (Write only) File name transfer
TR_BASStreamDataReg   = $ba   ; (Read Only) File transfer stream data
TR_BASStrAvailableReg = $bc   ; (Read Only) Signals stream data available

; Control Reg Commands/Actions:
TR_BASCont_None       = $00   ; No Action to be taken
TR_BASCont_SendFN     = $02   ; Prep to send Filename from BAS to TR
TR_BASCont_LoadPrep   = $04   ; Prep to load file from TR
TR_BASCont_SaveFinish = $06   ; Save file to TR
TR_BASCont_DirPrep    = $08   ; Load Dir into TR RAM

; StatReg Values:
TR_BASStat_Processing = $00   ; No update, still processing
;; Do not conflict with BASIC_Error_Codes (basic.ERROR_*)
TR_BASStat_Ready      = $55   ; Ready to Transfer

IO1Port  = $de00

_teensy_load:
   jsr SendFileName  ;send filename to TR

   ;check for file present & load into TR RAM
   ldx #TR_BASCont_LoadPrep
   stx TR_BASContReg+IO1Port
   jsr WaitForTR

   cpx #0
   beq laba
   rts

   ; load file into C64 memory
laba:
   ;ldy #$49   ;LOADING
   ;jsr $f12f  ;print message from table at $f0bd
   lda TR_BASStreamDataReg+IO1Port
   sta r0L
   lda TR_BASStreamDataReg+IO1Port
   sta r0H
   ldy #0   ;zero offset

labb: lda TR_BASStrAvailableReg+IO1Port ;are we done?
   beq labd   ;exit the loop (zero flag set)
   lda TR_BASStreamDataReg+IO1Port ;read from data reg, increments address & checks for end
   sta (r0), y
   iny

   bne labb
   inc r0H
   bne labb
   ;good luck if we get to here... Trying to overflow and write to zero page
   ldx #ERROR_OVERFLOW
   rts
labd:
   ldx #0
   rts

SendFileName:
    ; acc=msg len
    ; x=Message L pointer
    ; y=Message H pointer

    stx r0L
    sty r0H
    sta r1L

    ldx #TR_BASCont_SendFN
    stx TR_BASContReg+IO1Port  ;tell TR there's a FN coming

    ldy #0
labe:
    cpy r1L
    beq labf                     ;last char, exit

    lda (r0),y
    sta TR_BASFileNameReg+IO1Port ;write to TR filename reg
    iny
    bne labe ;255 char limit
labf:
    lda #$00
    sta TR_BASFileNameReg+IO1Port ;terminate/end filename transfer
    rts

; x = 0 for okay, else error
WaitForTR:
   ;inc $0400 ;spinner @ top/left
   lda TR_BASStatReg+IO1Port
   cmp #TR_BASStat_Processing
   beq WaitForTR
   ldx #5 ;require 1+5 consecutive reads of same (non-TR_BASStat_Processing) value to continue
labg:
   cmp TR_BASStatReg+IO1Port
   bne WaitForTR
   dex
   bne labg
   ;we have a validate result
   cmp #TR_BASStat_Ready  ;ready result?
   beq labh
   ldx #1
   rts
labh:
   ldx #0
   rts

.export _teensy_load
