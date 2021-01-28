# Extra Features

In addition to being compatible with a genuine VICII, VICII-Kawari
adds a number of new features for C64 and 8-bit hobbyests to experiment
with.

## Extra Registers

Extra registers are enabled through the activation port (0xd03f)
by poking it with the PETSCII bytes "VIC2".  This prevents existing software
from unintentionally triggering extra registers.

    POKE 54271,ASC("V")
    POKE 54271,ASC("I")
    POKE 54271,ASC("C")
    POKE 54271,ASC("2")

Once activated, registers 0xd02f - 0xd03f are available to access
VICII-Kawari extra features. Extra regsters can be deactivated again
by setting bit 5 of 0xd03f to 1.

### Extra Registers Table

REG    | Name | Description
-------|------|-------------
0xd02f |      | Unused
0xd030 |      | Unused
0xd031 |      | Unused
0xd032 |      | Unused
0xd033 |      | Unused
0xd034 |      | Unused
0xd035 | VIDEO_MEM_1_IDX | Video Memory Index Port A (RAM only)
0xd036 | VIDEO_MEM_2_IDX | Video Memory Index Port B (RAM only)
0xd037 | VIDEO_MODE1 | See below
0xd038 | VIDEO_MODE2 | See below
0xd039 | VIDEO_MEM_1_LO | Video Memory Addr Lo Port A
0xd03a | VIDEO_MEM_1_HI | Video Memory Addr Hi Port A
0xd03b | VIDEO_MEM_1_VAL | Video Memory Read/Write Value Port A
0xd03c | VIDEO_MEM_2_LO | Video Memory Addr Lo Port B
0xd03d | VIDEO_MEM_2_HI | Video Memory Addr Hi Port B
0xd03e | VIDEO_MEM_2_VAL | Video Memory Read/Write Value Port B
0xd03f | VIDEO_MEM_FLAGS | Video Memory Op Flags (see below)

## Video Memory

VICII-Kawari adds an extra 32k of video memory. This memory can be directly
accessed by VICII-Kawari for new graphics modes.  The registers 0xd039-0xd03f
are used to read/write from/to video memory. (This space can also be used to
store code but it would have to be copied back to main memory to be executed
by the CPU.)

VIDEO_MEM_FLAGS | Description
------------------------|------
BIT 1,2  | PORT 1 AUTO INCREMENT FLAGS<br>0=NONE<br>1=INC<br>2=DEC<br>3=UNUSED
BIT 3,4  | PORT 2 AUTO INCREMENT FLAGS<br>0=NONE<br>1=INC<br>2=DEC<br>3=UNUSED
BIT 5    | Deactivate Extra Registers
BIT 6    | Extra Registers Overlay at 0x0000 Enable/Disable
BIT 7    | UNUSED
BIT 8    | UNUSED

VIDEO_MODE1 | Description
------------|------------
BIT 1-3     | CHAR_PIXEL_BASE
BIT 4       | PALETTE SELECT
BIT 5       | HIRES ENABLE (640x200 mode)
BIT 6-7     | HIRES MODE (0=TEXT, 1=640x200, 2=320x200, 3=640x200)
BIT 8       | UNUSED

VIDEO_MODE2 | Description
------------|------------
BIT 1-4     | MATRIX_BASE
BIT 4-8     | COLOR_BASE

## Hires Enable
This bit controls whether the horizontal resolution is doubled or not.  It must be enabled for 80 column text or the bitmap modes.

## Hires Mode
These bit controls the hires video mode.

HIRES MODE | Description
-----------|-------------
0          | 80 Column Text 16 Colors (4K CharDef, 2K Matrix, 2K Color)
1          | 640x200 Bitmap 16 Colors (16K Bitmap, 2K Color)
2          | 320x200 Bitmap 16 Color 2 Planes (32K Bitmap)
3          | 640x200 Bitmap 4 Color 2 Planes (32K Bitmap)

### Writing to video memory from main DRAM using auto increment
    LDA <ADDR
    STA VIDEO_MEM_A_HI
    LDA >ADDR
    STA VIDEO_MEM_A_LO
    LDA #1               ; Auto increment port 1
    STA VIDEO_MEM_FLAGS
    LDA #$55
    STA VIDEO_MEM_A_VAL  ; write $55 to video mem ADDR

    Suquential writes will auto increment the address:

    LDA #$56
    STA VIDEO_MEM_A_VAL  ; write $56 to ADDR+1
    LDA #$57
    STA VIDEO_MEM_A_VAL  ; write $57 to ADDR+2
    (...etc)

    * video mem hi/lo pairs will wrap as expected

### Reading from video memory into main DRAM using auto increment
    LDA <ADDR
    STA VIDEO_MEM_A_HI
    LDA >ADDR
    STA VIDEO_MEM_A_LO
    LDA #1               ; Auto increment port 1
    STA VIDEO_MEM_FLAGS
    LDA VIDEO_MEM_A_VAL  ; read the value

    Sequential reads will auto increment the address:

    LDA VIDEO_MEM_A_VAL ; read from ADDR+1
    LDA VIDEO_MEM_A_VAL ; read from ADDR+2
    (...etc)

    * video mem hi/lo pairs will wrap as expected

### Performing a move within video memory

Moving memory still requires CPU but uses two ports; one for
a source and the other for a destination.

    LDA <SRC_ADDR
    STA VIDEO_MEM_A_HI
    LDA >SRC_ADDR
    STA VIDEO_MEM_A_LO

    LDA <DEST_ADDR
    STA VIDEO_MEM_B_HI
    LDA >DEST_ADDR
    STA VIDEO_MEM_B_LO

    LDA #5               ; Auto increment port 1 and 2
    STA VIDEO_MEM_FLAGS

    LDA VIDEO_MEM_A_VAL  ; read from src
    STA VIDEO_MEM_B_VAL  ; write to dest

    Sequential read/writes will auto increment/decrement the address as above.

### Using video mem pointers with an index

Sometimes, it may be more convenient to use an index when porting existing code to use VICII-Kawari extended video memory.  This is useful if replacing indirect indexed addressing.

For example, the code:

    LDY #20
    LDA #00
    STA $fc
    LDA #04
    STA $fd
    LDA ($fc),y

Can be replaced with:

    LDY #20
    LDA #00
    STA VIDEO_MEM_A_LO
    LDA #04
    STA VIDEO_MEM_A_HI
    STY VIDEO_MEM_A_IDX
    LDA VIDEO_MEM_A_VAL

NOTE: VIDEO_MEM_?_IDX only applies to RAM access, not the extended register
      overlay area between 0x00 - 0xff described below.

### Extra Registers Overlay

When BIT 6 of the VIDEO_MEM_FLAGS register is set, the first 256 bytes
of video RAM is mapped to extra registers for special VICII-Kawari
functions.

### Color Registers

VICII-Kawari has a configurable color palette. The 16 colors can be selected
from a palette of 4096 colors by specifying three 4-bit RGB values. (The
upper 4 bits in each byte are ignored).  The palette is also double buffered
to allow changing all colors instantaneously with the palette select bit in
register VIDEO_MODE1. Palette 0 is located at 0x0000. Palette 1 is located at
0x0040.

Register | Description
-------|-------------------
0x0000 | Palette 0 Color0_R
0x0001 | Palette 0 Color0_G
0x0002 | Palette 0 Color0_B
0x0003 | Unused
0x0004 | Palette 0 Color1_R
0x0005 | Palette 0 Color1_G
0x0006 | Palette 0 Color1_B
0x0007 | Unused
0x0008 | Palette 0 Color2_R
0x0009 | Palette 0 Color2_G
0x000a | Palette 0 Color2_B
0x000b | Unused
0x000c | Palette 0 Color3_R
0x000d | Palette 0 Color3_G
0x000e | Palette 0 Color3_B
0x000f | Unused
0x0010 | Palette 0 Color4_R
0x0011 | Palette 0 Color4_G
0x0012 | Palette 0 Color4_B
0x0013 | Unused
0x0014 | Palette 0 Color5_R
0x0015 | Palette 0 Color5_G
0x0016 | Palette 0 Color5_B
0x0017 | Unused
0x0018 | Palette 0 Color6_R
0x0019 | Palette 0 Color6_G
0x001a | Palette 0 Color6_B
0x001b | Unused
0x001c | Palette 0 Color7_R
0x001d | Palette 0 Color7_G
0x001e | Palette 0 Color7_B
0x001f | Unused
0x0020 | Palette 0 Color8_R
0x0021 | Palette 0 Color8_G
0x0022 | Palette 0 Color8_B
0x0023 | Unused
0x0024 | Palette 0 Color9_R
0x0025 | Palette 0 Color9_G
0x0026 | Palette 0 Color9_B
0x0027 | Unused
0x0028 | Palette 0 ColorA_R
0x0029 | Palette 0 ColorA_G
0x002a | Palette 0 ColorA_B
0x002b | Unused
0x002c | Palette 0 ColorB_R
0x002d | Palette 0 ColorB_G
0x002e | Palette 0 ColorB_B
0x002f | Unused
0x0030 | Palette 0 ColorC_R
0x0031 | Palette 0 ColorC_G
0x0032 | Palette 0 ColorC_B
0x0033 | Unused
0x0034 | Palette 0 ColorD_R
0x0035 | Palette 0 ColorD_G
0x0036 | Palette 0 ColorD_B
0x0037 | Unused
0x0038 | Palette 0 ColorE_R
0x0039 | Palette 0 ColorE_G
0x003a | Palette 0 ColorE_B
0x003b | Unused
0x003c | Palette 0 ColorF_R
0x003d | Palette 0 ColorF_G
0x003e | Palette 0 ColorF_B
0x003f | Unused

Register | Description
-------|-------------------
0x0040 | Palette 1 Color0_R
0x0041 | Palette 1 Color0_G
0x0042 | Palette 1 Color0_B
0x0043 | Unused
0x0044 | Palette 1 Color1_R
0x0045 | Palette 1 Color1_G
0x0046 | Palette 1 Color1_B
0x0047 | Unused
0x0048 | Palette 1 Color2_R
0x0049 | Palette 1 Color2_G
0x004a | Palette 1 Color2_B
0x004b | Unused
0x004c | Palette 1 Color3_R
0x004d | Palette 1 Color3_G
0x004e | Palette 1 Color3_B
0x004f | Unused
0x0050 | Palette 1 Color4_R
0x0051 | Palette 1 Color4_G
0x0052 | Palette 1 Color4_B
0x0053 | Unused
0x0054 | Palette 1 Color5_R
0x0055 | Palette 1 Color5_G
0x0056 | Palette 1 Color5_B
0x0057 | Unused
0x0058 | Palette 1 Color6_R
0x0059 | Palette 1 Color6_G
0x005a | Palette 1 Color6_B
0x005b | Unused
0x005c | Palette 1 Color7_R
0x005d | Palette 1 Color7_G
0x005e | Palette 1 Color7_B
0x005f | Unused
0x0060 | Palette 1 Color8_R
0x0061 | Palette 1 Color8_G
0x0062 | Palette 1 Color8_B
0x0063 | Unused
0x0064 | Palette 1 Color9_R
0x0065 | Palette 1 Color9_G
0x0066 | Palette 1 Color9_B
0x0067 | Unused
0x0068 | Palette 1 ColorA_R
0x0069 | Palette 1 ColorA_G
0x006a | Palette 1 ColorA_B
0x006b | Unused
0x006c | Palette 1 ColorB_R
0x006d | Palette 1 ColorB_G
0x006e | Palette 1 ColorB_B
0x006f | Unused
0x0070 | Palette 1 ColorC_R
0x0031 | Palette 1 ColorC_G
0x0072 | Palette 1 ColorC_B
0x0073 | Unused
0x0074 | Palette 1 ColorD_R
0x0075 | Palette 1 ColorD_G
0x0076 | Palette 1 ColorD_B
0x0077 | Unused
0x0078 | Palette 1 ColorE_R
0x0079 | Palette 1 ColorE_G
0x007a | Palette 1 ColorE_B
0x007b | Unused
0x007c | Palette 1 ColorF_R
0x007d | Palette 1 ColorF_G
0x007e | Palette 1 ColorF_B
0x007f | Unused

## Other registers

Location | Name | Description
---------|------|------------
0x0080 | VIDEO_STD | Video Standard Select (0=PAL, 1=NTSC)
0x0081 | VIDEO_FREQ | Video Frequency Select (0=15.7 khz, 1=34.1 khz)
0x0082 | CHIP_MODEL | Chip Model Select (0=6567R56A, 1=6567R8, 2=6569, 3-7 Reserved)
0x0083 | VERSION | Version (high nibble major, low nibble minor) - Read Only
0x0084 | DISPLAY_FLAGS | Bit 0 = Rasterlines Select
0x0085 - 0x008f | Reserved
0x0090 - 0xd09f | VARIANT_NAME | Variant Name
0x00a0 - 0xd0ff | Unused

### Variant Name

The extra register overlay area 0x0090 - 0xd09f is used to identify the
variant name. This is a max 16 byte null terminated PETSCII string.  All
forks should change this to something other than 'official' if they plan
on releasing a bitstream. See [FORKING.md](FORKING.md)

## Notes

As stated above, the extra registers described here should remain
functional across all VICII-Kawari variants. This way, the
official configuration utility will be able to at least query the variant
name and version on any variant (as well as set palette colors,
change video standard, or other common features between variants).
Users will be able to at least identify what variant they are running
even if they use the official config utility.  Also, programs can
run a simple check routine that will run on all variants and can
display a user friendly message indicating the wrong variant is installed.

