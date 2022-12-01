# VMEM Uitlity Routines

This program installs some VMEM utility routines that can be called from BASIC to access video memory.

# Routines

Routine         | Usage              | Description
----------------|--------------------|------------------
VPOKE LOC,VAL   | SYS 49152,LOC,VAL  | Poke video memory at 16-bit LOC with byte VAL. This is the 'unsafe' version that does not attempt to save/restore existing video memory pointers. This will be slightly faster than the 'safe' versions below.
VAL=VPEEK(LOC)  | SYS 49155,LOC,0:VAL=PEEK(780) | Peek video memory at 16-bit LOC and read into VAL. This is the 'unsafe' version that does not attempt to save/restore existing video memory pointers. This will be slightly faster than the 'safe' versions below.
VPOKE LOC,VAL   | SYS 49158,LOC,VAL  | This is identical to VPOKE except vmem pointers are not destroyed.
VAL=VPEEK(LOC)  | SYS 49161,LOC,0:VAL=PEEK(780) | This is identical to VPEEK except vmem pointers are not destroyed.
