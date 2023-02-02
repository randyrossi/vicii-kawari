!to "80col-loader.prg",plain
*=$033c
   LDA #11
   LDX #<NAME
   LDY #>NAME
   JSR $FFBD ; SETNAM
   LDA #4 ; logical file
   LDX #8 ; floppy drive
   LDY #1 ; use location bytes
   JSR $FFBA ; SETLFS
   LDA #0 ; LOAD = 0, VERIFY = 1
   JSR $FFD5 ; LOAD
   RTS
NAME !BYTE '8','0','C','O','L','-','5','1','2','0','0'
