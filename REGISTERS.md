Extra registers will not be enabled unless the activation port (0x3f)
is poked with the PETSCII bytes "VIC2".  This prevents existing software
from unintentionally triggering extra registers.

    POKE 54271,ASC("V")
    POKE 54271,ASC("I")
    POKE 54271,ASC("C")
    POKE 54271,ASC("2")

Once exra registers are enabled, registers 0x2f - 0x3a are available for
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

Registers 0x3b - 0x3f are reserved across all variants for extra memory
access.  This mechanism allows addressing up to 16 banks of 64k each.

REG | Notes
----|----------------------
0x3b|EXTRA_MEM_ADDR_HI
0x3c|EXTRA_MEM_ADDR_LO
0x3d|EXTRA_MEM_OP (see below)
0x3e|EXTRA_MEM_VALUE
0x3f|EXTENSION_ACTIVATION

EXTRA_MEM_OP            | Notes
------------------------|------
BIT 1                   | 0 = READ<br>1 = WRITE
BIT 2,3                 | 0 = NO INCREMENT<br>1 = AUTO INCREMENT ADDR<br>2 = AUTO DECREMENT ADDR<br>3 = UNUSED
BIT 4                   | 1 = REG/ROM OVERLAY, 0 = NO REG/ROM OVERLAY (Bank 0)
BIT 5-8                 | BANK (0-15)

### Writing to extra memory
    LDA <ADDR
    STA $d33b  ; addr hi
    LDA >ADDR
    STA $d33c  ; addr lo
    LDA #$55
    STA $d33e  ; prepare byte for write
    LDA #1
    STA $d33d  ; perform the write

### Reading from extra memory
    LDA <ADDR
    STA $d33b  ; addr hi
    LDA >ADDR
    STA $d33c  ; addr lo
    LDA #0
    STA $d33d  ; perform the read
    LDA $d33e  ; read the value
   
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

Location  | Notes
----------|------------------------------
0x0000    | Col0R Col0G Col0B Unused (RW)
0x0004    | Col1R Col1G Col1B Unused (RW)
0x0008    | Col2R Col2G Col2B Unused (RW)
0x000c    | Col3R Col3G Col3B Unused (RW)
0x0010    | Col4R Col4G Col4B Unused (RW)
0x0014    | Col5R Col5G Col5B Unused (RW)
0x0018    | Col6R Col6G Col6B Unused (RW)
0x001c    | Col7R Col7G Col7B Unused (RW)
0x0020    | Col8R Col8G Col8B Unused (RW)
0x0024    | Col9R Col9G Col9B Unused (RW)
0x0028    | ColaR ColaG ColaB Unused (RW)
0x002c    | ColbR ColbG ColbB Unused (RW)
0x0030    | ColcR ColcG ColcB Unused (RW)
0x0034    | ColdR ColdG ColdB Unused (RW)
0x0038    | ColeR ColeG ColeB Unused (RW)
0x003c    | ColfR ColfG ColfB Unused (RW)
0x0040    | Video Standard Select (0=PAL, 1=NTSC) (RW)
0x0041    | Video Standard Select (0=15.7, 1=34.1 khz) (RW)
0x0042    | Chip Model Select (0=6567R56A, 1=6567R8, 2=6569, (3-7) reserved (RW)
0x0043    | Version (high nibble = major, low nibble = minor) (RO)
0x0044    | Config Operation (0=SAVE, 1=RESET)
0x0045    | Palette Reset Port (WO)
0x0046    | Auto Increment Value (RW) (Default 1, Two's complement)
0x0047    | Num Banks Available (RO)
0x0048    | Half brightness on alt lines Enable/Disable (HDMI/VGA only)

Location  | Notes
----------|------------------------------
0x0049<br>to<br>0x005f | Reserved for official
0x0060<br>to<br>0x00ff | Available for variants

### R/W Memory

Location               | Notes
-----------------------|------------------------------
0x0100<br>to<br>0x010f | Variant String (null terminated, max 16 bytes)
0x0110<br>to<br>0x03ff | Capability Strings (double null terminated, max 512 bytes)
0x0400<br>to<br>0xffff | Free space
