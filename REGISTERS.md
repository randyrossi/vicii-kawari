Extra registers will not be enabled unless the activation port (0x3f)
is poked with the PETSCII bytes "VIC2".  This prevents existing software
from unintentionally triggering extra registers.

    POKE 54271,ASC("V")
    POKE 54271,ASC("I")
    POKE 54271,ASC("C")
    POKE 54271,ASC("2")

Once exra registers are enabled, registers 0x2f - 0x3b are available for
variants to use for direct CPU access.  The meaning of these will be variant
dependent.

REG | Notes
----|----------------------
0x2f|AVAILABLE FOR VARIANTS
0x30|AVAILABLE FOR VARIANTS
0x31|AVAILABLE FOR VARIANTS
0x32|AVAILABLE FOR VARIANTS
0x33|AVAILABLE FOR VARIANTS
0x34|AVAILABLE FOR VARIANTS
0x35|AVAILABLE FOR VARIANTS
0x36|AVAILABLE FOR VARIANTS
0x37|AVAILABLE FOR VARIANTS
0x38|AVAILABLE FOR VARIANTS
0x39|AVAILABLE FOR VARIANTS
0x3a|AVAILABLE FOR VARIANTS
0x3b|AVAILABLE FOR VARIANTS

Registers 0x3c - 0x3f are reserved across all variants for extra memory
access. This mechanism allows addressing up to 16 banks of 64k each. It
can also be used to access a bank of additional registers as well as
some ROM that identifies the variant and its capabilities.

REG | Notes
----|----------------------
0x3c|EXTRA_MEM_ADDR_HI
0x3d|EXTRA_MEM_ADDR_LO
0x3e|EXTRA_MEM_VALUE
0x3f|EXTENSION_ACTIVATION or EXTRA_MEM_OP (see below)

EXTRA_MEM_OP            | Notes
------------------------|------
BIT 1&2                 | 0 = NO INCREMENT<br>1 = AUTO INCREMENT ADDR<br>2 = AUTO DECREMENT ADDR<br>3 = RESERVED
BIT 3                   | 1 = REG/ROM OVERLAY, 0 = NO REG/ROM OVERLAY (Bank 0)
BIT 4-7                 | BANK (0-15)
BIT 8                   | RESERVED

### Writing to extra memory
    LDA <ADDR
    STA $d33c  ; addr hi
    LDA >ADDR
    STA $d33d  ; addr lo
    LDA #1     ; auto increment, bank 0 no overlay
    STA $d33f  ; set op
    LDA #$55
    STA $d33e  ; write $55 to ADDR

    Suquential writes will auto increment the address:

    LDA #$56
    STA $d33e  ; write $56 to ADDR+1
    LDA #$57
    STA $d33e  ; write $57 to ADDR+2
    (...etc)

### Reading from extra memory
    LDA <ADDR
    STA $d33c  ; addr hi
    LDA >ADDR
    STA $d33d  ; addr lo
    LDA #1     ; auto increment, bank 0 no overlay
    STA $d33f  ; set op
    LDA $d33e  ; read the value

    Sequential reads will auto increment the address:

    LDA $d33e  ; read from ADDR+1
    LDA $d33e  ; read from ADDR+2
    (...etc)
   
When BIT 4 of register EXTRA_MEM_OP is set, the first 256 bytes
of extra mem BANK 0 is mapped to extra registers and the next 768 bytes
is mapped to ROM. These registers and ROM should remain consistent between
VICII-Kawari variants for two reasons: 

1) the official configuration utility will be able to at
least query the variant and capability strings on any
variant (as well as set palette colors, change video
standard, or other common features between variants).
Users will be able to at least find out what variant
they are running even if they use the official config
utiliy.

2) programs can query what the variant is on the system
they are running on in a consistent way. This will allow
for a simple check routine that will run on all variants
and can product a friendly user message indicating the
wrong variant is installed.

### Bank 0 REG/ROM Overlay

NOTE: 0x0000 - 0x03FF overlay is enabled by BIT 4 of EXTRA_MEM_OP. Otherwise, the full 64k in the bank is available for R/W.

Location  | Description
----------|------------------------------
0x0000    | Video Standard Select (0=PAL, 1=NTSC) (RW)
0x0001    | Video Standard Select (0=15.7, 1=34.1 khz) (RW)
0x0002    | Chip Model Select (0=6567R56A, 1=6567R8, 2=6569, (3-7) reserved (RW)
0x0003    | Version (high nibble = major, low nibble = minor) (RO)
0x0004    | Config Operation (see below)
0x0005    | Bits 0-3 = Num extra memory banks available (RO)
0x0006    | Bit 0 = Raster Effect, Bit 1 = Video Extensions Enable, 2-6 Reserved
0x0007    | Color 0-7 HI/LO Nibble Select
0x0008    | Color 8-f HI/LO Nibble Select
0x0009<br>to<br>0x000f | Reserved for future use

Location  | Description
----------|------------------------------
0x0010    | Color0_R_HI_Nibble + Color0_R_LO_Nibble
0x0011    | Color0_G_HI_Nibble + Color0_G_LO_Nibble
0x0012    | Color0_B_HI_Nibble + Color0_B_LO_Nibble
0x0013    | Color1_R_HI_Nibble + Color1_R_LO_Nibble
0x0014    | Color1_G_HI_Nibble + Color1_G_LO_Nibble
0x0015    | Color1_B_HI_Nibble + Color1_B_LO_Nibble
0x0016    | Color2_R_HI_Nibble + Color2_R_LO_Nibble
0x0017    | Color2_G_HI_Nibble + Color2_G_LO_Nibble
0x0018    | Color2_B_HI_Nibble + Color2_B_LO_Nibble
0x0019    | Color3_R_HI_Nibble + Color3_R_LO_Nibble
0x001a    | Color3_G_HI_Nibble + Color3_G_LO_Nibble
0x001b    | Color3_B_HI_Nibble + Color3_B_LO_Nibble
0x001c    | Color4_R_HI_Nibble + Color4_R_LO_Nibble
0x001d    | Color4_G_HI_Nibble + Color4_G_LO_Nibble
0x001e    | Color4_B_HI_Nibble + Color4_B_LO_Nibble
0x001f    | Color5_R_HI_Nibble + Color5_R_LO_Nibble
0x0020    | Color5_G_HI_Nibble + Color5_G_LO_Nibble
0x0021    | Color5_B_HI_Nibble + Color5_B_LO_Nibble
0x0022    | Color6_R_HI_Nibble + Color6_R_LO_Nibble
0x0023    | Color6_G_HI_Nibble + Color6_G_LO_Nibble
0x0024    | Color6_B_HI_Nibble + Color6_B_LO_Nibble
0x0025    | Color7_R_HI_Nibble + Color7_R_LO_Nibble
0x0026    | Color7_G_HI_Nibble + Color7_G_LO_Nibble
0x0027    | Color7_B_HI_Nibble + Color7_B_LO_Nibble
0x0028    | Color8_R_HI_Nibble + Color8_R_LO_Nibble
0x0029    | Color8_G_HI_Nibble + Color8_G_LO_Nibble
0x002a    | Color8_B_HI_Nibble + Color8_B_LO_Nibble
0x002b    | Color9_R_HI_Nibble + Color9_R_LO_Nibble
0x002c    | Color9_G_HI_Nibble + Color9_G_LO_Nibble
0x002d    | Color9_B_HI_Nibble + Color9_B_LO_Nibble
0x002e    | ColorA_R_HI_Nibble + ColorA_R_LO_Nibble
0x002f    | ColorA_G_HI_Nibble + ColorA_G_LO_Nibble
0x0030    | ColorA_B_HI_Nibble + ColorA_B_LO_Nibble
0x0031    | ColorB_R_HI_Nibble + ColorB_R_LO_Nibble
0x0032    | ColorB_G_HI_Nibble + ColorB_G_LO_Nibble
0x0033    | ColorB_B_HI_Nibble + ColorB_B_LO_Nibble
0x0034    | ColorC_R_HI_Nibble + ColorC_R_LO_Nibble
0x0035    | ColorC_G_HI_Nibble + ColorC_G_LO_Nibble
0x0036    | ColorC_B_HI_Nibble + ColorC_B_LO_Nibble
0x0037    | ColorD_R_HI_Nibble + ColorD_R_LO_Nibble
0x0038    | ColorD_G_HI_Nibble + ColorD_G_LO_Nibble
0x0039    | ColorD_B_HI_Nibble + ColorD_B_LO_Nibble
0x003a    | ColorE_R_HI_Nibble + ColorE_R_LO_Nibble
0x003b    | ColorE_G_HI_Nibble + ColorE_G_LO_Nibble
0x003c    | ColorE_B_HI_Nibble + ColorE_B_LO_Nibble
0x003d    | ColorF_R_HI_Nibble + ColorF_R_LO_Nibble
0x003e    | ColorF_G_HI_Nibble + ColorF_G_LO_Nibble
0x003f    | ColorF_B_HI_Nibble + ColorF_B_LO_Nibble

* 0x0007 and 0x0008 regs allow the instantaneous switching of colors by
defining two color palettes. The CPU can set RGB values then swap the nibble
select bit(s).  Otherwise, several pixels would render with unwanted
intermediate RGB color combinations.


Location  | Description
----------|------------------------------
0x0040<br>to<br>0x00ff | Available for variants


Location               | Description
-----------------------|------------------------------
0x0100<br>to<br>0x010f | Variant String (null terminated, max 16 bytes)
0x0110<br>to<br>0x03ff | Capability Strings (double null terminated, max 512 bytes)
0x0400<br>to<br>0xffff | RAM


Config Operation        | Description
------------------------|------
0                       | Save
1                       | Reset VIC and Computer
2                       | Restore Default Palette
3                       | Disable extra registers
