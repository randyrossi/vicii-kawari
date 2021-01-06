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

0x2f AVAILABLE FOR VARIANTS
0x30 AVAILABLE FOR VARIANTS
0x31 AVAILABLE FOR VARIANTS
0x32 AVAILABLE FOR VARIANTS
0x33 AVAILABLE FOR VARIANTS
0x34 AVAILABLE FOR VARIANTS
0x35 AVAILABLE FOR VARIANTS
0x36 AVAILABLE FOR VARIANTS
0x37 AVAILABLE FOR VARIANTS
0x38 AVAILABLE FOR VARIANTS
0x39 AVAILABLE FOR VARIANTS
0x3a AVAILABLE FOR VARIANTS

Registers 0x3b - 0x3f are reserved across all variants for extra memory
access.  This mechanism allows addressing up to 32 banks of 64k each.

0x3b EXTRA MEM ADDR HI
0x3c EXTRA MEM ADDR LO
0x3d EXTRA MEM OPERATION
     BIT 1   = 0 = READ, 1 = WRITE
     BIT 2,3 = 0 = NO INCREMENT
               1 = AUTO INCREMENT ADDR
               2 = AUTO DECREMENT ADDR
               3 = UNUSED
     BIT 4-8 = BANK
0x3e EXTRA MEM SET/GET VALUE
0x3f EXTRA MEM ACTIVATION PORT

Writing to an extra register
    POKE 0xd33b, ADDRHI
    POKE 0xd33c, ADDRLO
    POKE 0xd33e, VALUE     prepare byte for write
    POKE 0xd33d, 1         performs the write

Reading from an extra register
    POKE 0xd33b, ADDRHI
    POKE 0xd33c, ADDRLO
    POKE 0xd33d, 0         performs the read
    val = PEEK(0xd33e)     retrieve byte read
   
The first 256 bytes of extra mem is mapped to extra registers.
These registers should remain consistent between VICII-Kawari
variants for two reasons: 

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

Extra Registers
---------------
0x0000    : Col0R Col0G Col0B Unused (RW)
0x0004    : Col1R Col1G Col1B Unused (RW)
0x0008    : Col2R Col2G Col2B Unused (RW)
0x000c    : Col3R Col3G Col3B Unused (RW)
0x0010    : Col4R Col4G Col4B Unused (RW)
0x0014    : Col5R Col5G Col5B Unused (RW)
0x0018    : Col6R Col6G Col6B Unused (RW)
0x001c    : Col7R Col7G Col7B Unused (RW)
0x0020    : Col8R Col8G Col8B Unused (RW)
0x0024    : Col9R Col9G Col9B Unused (RW)
0x0028    : ColaR ColaG ColaB Unused (RW)
0x002c    : ColbR ColbG ColbB Unused (RW)
0x0030    : ColcR ColcG ColcB Unused (RW)
0x0034    : ColdR ColdG ColdB Unused (RW)
0x0038    : ColeR ColeG ColeB Unused (RW)
0x003c    : ColfR ColfG ColfB Unused (RW)
0x0040    : Video Standard Select (0=PAL/NTSC, 1=15.7/34.1 khz) (RW)
0x0041    : Chip Model Select (0=6567R56A, 1=6567R8, 2=6569, (3-7) reserved (RW)
0x0042    : Minor Version (RO)
0x0043    : Major Version (RO)
0x0044    : Reset Port (WO)
0x0045    : Palette Reset Port (WO)
0x0046    : Auto Increment Value (RW)
0x0046    : Save Port (WO)
0x0047    : Num Banks (RO)

0x0048
  |       : Reserved for official
0x005f

0x0060
  |       : Available for variants
0x00ff

R/W Memory
----------
0x0100    
  |       : Variant String (null terminated, max 16 bytes)
0x010f

0x0110
  |       : Capability Strings (double null terminated, max 512 bytes)
0x030f

0x0310
  |       : Free
x0ffff

