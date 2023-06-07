Back to [README.md](../README.md)

# Extra Features

In addition to being compatible with a genuine VIC-II, VIC-II Kawari adds a number of new features.

## Extra Registers

Extra registers are enabled through the activation port (0xd03f) by poking it with the PETSCII bytes "VIC2". This prevents existing software from unintentionally triggering extra registers. NOTE: If lock bit jumper #2 is removed, extra registers cannot be activated.

### BASIC
    POKE 53311,ASC("V")
    POKE 53311,ASC("I")
    POKE 53311,ASC("C")
    POKE 53311,ASC("2")

### 6510 ASSEMBLY
    LDA #86 ; 'V'
    STA $d03f
    LDA #73 ; 'I'
    STA $d03f
    LDA #67 ; 'C'
    STA $d03f
    LDA #50 ; '2'
    STA $d03f

Once activated, registers 0xd02f - 0xd03f become available and may be used to access VIC-II Kawari extra features. Extra regsters can be deactivated again by setting bit 8 of 0xd03f to 1.

### Extra Registers Table

REG    | Name | Description
-------|------|-------------
0xd02f | OP_1_HI/RESULT_HH | Math Operand 1 HI on write, Result 31-25
0xd030 | OP_1_LO/RESULT_HL | Math Operand 1 LO on write, Result 24-16
0xd031 | OP_2_HI/RESULT_LH | Math Operand 2 HI on write, Result 15-8
0xd032 | OP_2_LO/RESULT_LL | Math Operand 2 LO on write, Result 7-0
0xd033 | OPERATOR/OPERATOR_FLAGS | Math Operator on write, Operation Flags on read
0xd034 | SPI_REG | SPI Programming Register / Status Register
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

### Math Operations

VIC-II Kawari has signed and unsigned multiply and divide operations which can eliminate expensive loops on the CPU and achieve the same result.  All math operands are 16-bit.

OPERATOR    | Value | Description
------------|-------|-------------
U_MULT      | 0     | Unsigned multiply OP_1 * OP_2
U_DIV       | 1     | Unsigned divide OP_1 / OP_2
S_MULT      | 2     | Signed multiply OP_1 * OP_2
S_DIV       | 3     | Signed divide OP_1 / OP_2

OPERATION   | Result Format
------------|--------------
U_MULT      | 32-bit unsigned in RESULT_HH RESULT_HL RESULT_LH RESULT_LL
U_DIV       | 16-bit remainder in RESULT_HH RESULT_HL, 16-bit quotient in RESULT_LH RESULT_LL
S_MULT      | 32-bit signed in RESULT_HH RESULT_HL RESULT_LH RESULT_LL
S_DIV       | 16-bit remainder in RESULT_HH RESULT_HL, 16-bit quotient in RESULT_LH RESULT_LL

OPERATOR_FLAGS | Description
---------------|------------
1              | Div By Zero

## SPI Programming Register / Status Register ($d034)

This register is used by config/flash programs to update the FPGA bitstream. The SPI register is not enabled unless it is first POKEd with the sequence 'S','P','I'.

On Write:

Bit          | Bit 8=0                | Bit 8=1
-------------|------------------------|-------------
Bit 1        | Flash SPI Select Line  | Bulk Flash Op
Bit 2        | SPI Clock Line         | Bulk Flash Op
Bit 3        | SPI Data Out Line      | Bulk Flash Op
Bit 4        | EEPROM SPI Select Line | Bulk Flash Op
Bit 5        | Unused                 | Bulk Flash Op
Bit 6        | Unused                 | Bulk Flash Op
Bit 7        | Unused                 | Bulk Flash Op
Bit 8        | 0=Set SPI Lines, 1=Bulk SPI Operation

Bulk Flash Op | Operation
--------------|------------
0000001       | BULK WRITE
0000010       | BULK READ

### For bulk flash operations
    24 bit Flash Address = { VIDEO_MEM_1_IDX, VIDEO_MEM_1_HI, VIDEO_MEM_1_LO }
    16 bit VMEM Address = { VIDEO_MEM_2_HI, VIDEO_MEM_2_LO }

Bulk flash operations always operate on 16k pages.

On Read:

Bit          | Bit 8=0
-------------|---------
Bit 1        | Spi Data In Line
Bit 2        | Bulk Flash Operation Busy
Bit 3        | Bulk Flash Operation Verify Error
Bit 4        | SPI Lock Status
Bit 5        | Extensions Lock Status
Bit 6        | Persistence Lock Status
Bit 7        | Unused
Bit 8        | Unused

## Hardware Locks

Jumper | Name | Function
-------|------|---------
1 | SPI Lock | OPEN=ALLOW SPI PROGRAMMING, SHORT=DISALLOW SPI PROGRAMMING
2 | Extensions Lock | OPEN=DISALLOW EXTENSIONS, SHORT=ALLOW EXTENSIONS
3 | Persistence Lock | OPEN=DISALLOW PERSISTENCE, SHORT=ALLOW PERSISTENCE

Pin 1 - SPI Lock must be OPEN for flash updates to work.

Pin 2 - Extensions Lock can be left OPEN to prevent any access to extra extensions. This effectively turns VIC-II Kawari into a normal 6567/6569 chip with no extra features accessible.

Pin 3 - Persistence Lock can be left OPEN to prevent overwriting existing saved settings (rasterlines, colors, hdmi/vga/settings, etc). (Chip model is exempt from this lock)

## Video Memory

VIC-II Kawari adds 64k of video memory to the C64. This memory can be directly accessed by VIC-II Kawari for new graphics modes and indirectly by the 6510 CPU. The registers 0xd039-0xd03f are used to read/write from/to video memory. (This space can also be used to store code but it would have to be copied back to main memory to be executed by the CPU.)

VIDEO_MEM_FLAGS | Description
----------------|-------------
BIT 1,2  | PORT 1 FUNCTION <br>0=NONE<br>1=AUTO INC<br>2=AUTO DEC<br>3=DMA
BIT 3,4  | PORT 2 FUNCTION <br>0=NONE<br>1=AUTO INC<br>2=AUTO DEC<br>3=DMA
BIT 5    | Persist busy status flag (see below)
BIT 6    | Extra 256 registers overlay at 0x0000 Enable/Disable
BIT 7    | Persist Flag (see below)
BIT 8    | Deactivate Extra Registers

When BIT 7 is 1, changes to some registers (like color palette, composite luma, phase, amplitude, etc) will be persisted to the EEPROM and restored on reboot. Each register change must be written to the EEPROM which may not be able to keep up with many register changes back to back. To avoid lost changes, the 6502 should check BIT 5 and make sure it is 0 before attempting to set the next register. For boards that do not support persistence, BIT 7 has no function and BIT 5 is always 0.  If BIT 7 is not enabled, BIT 5 can be ignored.

VIDEO_MODE1 | Description
------------|------------
BIT 3-1     | CHAR_PIXEL_BASE
BIT 4       | HIRES ALLOW BADLINES ON LORES MODES (0=no, 1=yes)
BIT 5       | HIRES ENABLE
BIT 8-6     | HIRES MODE

HIRES MODE | Description
-----------|------------
000 | 80 Column Text
001 | 640x200x16 8x8 color cells (low color nibble=foreground, d020 background)
010 | 320x200x16
011 | 640x200x16
100 | 160x200x16


VIDEO_MODE2 | Description
------------|------------
BIT 1-4     | MATRIX_BASE
BIT 5-8     | COLOR_BASE


## Color Memory
For the 80 column text mode, each byte stores color information as well as display attributes.

BIT        | Description
-----------|-------------
1-4        | 16 color index
5          | blink (every 32 frames)
6          | underscore
7          | reverse video
8          | alt char set

## Hires Enable
This bit must be 1 for any of the hi-resolution modes to be visible.  When enabled, bit 4 of VIDEO_MODE1 will determine whether badlines normally generated by the 40 column mode are enabled/disabled. When disabled, it is as though the DEN bit is set to 0.

## Hires Mode
These bit controls the hires video mode.

HIRES MODE | Description
-----------|-------------
0          | 80 Column Text 16 Colors (4K CharDef, 2K Matrix, 2K Color)
1          | 640x200 Bitmap 16 Colors (16K Bitmap, 2K Color - 8x8 color cells)
2          | 320x200 Bitmap 16 Color (32K Bitmap, packed pixels, 2 pixels per byte)
3          | 640x200 Bitmap 4 Color (32K Bitmap, packed pixels, 4 pixels per byte)

### Mode 000 : 80 Column Text

Base Pointer    | Description                                     | Range             | Restrictions
----------------|-------------------------------------------------|-------------------|------------------
CHAR_PIXEL_BASE | Points to a 4k block with character ROM data    | XXXXX000-XXXXX111 | lower 32k only
MATRIX_BASE     | Points to a 2k block for 80x25 character matrix | XXXX0000-XXXX1111 | lower 32k only
COLOR_BASE      | Points to a 2k block for 80x25 color matrix     | XXXX0000-XXXX1111 | lower 32k only

    This works much like 40 column text mode except matrix bytes are fetched on both HIGH and LO
    PHI cycles giving 80 bytes per line:

    VC (11 bit matrix counter, repeats for 8 rows)
    RC (3 bit row counter : 0-7)

    Color Fetch Addr (15): COLOR_BASE(4) | VC(11)
    Matrix Fetch Addr (15):  MATRIX_BASE(4) | VC(11)
    Char Pixel Fetch Addr (15): CHAR_PIXEL_BASE(3) | CASE_BIT(1) | CHAR_NUM(8) | RC(3)

    There are no 'badlines' in hires modes since the video memory is dual port and can be accessed by hires pixel sequencer and the CPU at the same time.  However, yscroll will still trigger a reset of the row counter as it does in the legacy modes. (NOTE: Badlines for hires modes can be enabled/disabled. See BIT 4 of VIDEO_MODE1 register.  If disabled, an additional 6% (approximately) worth of 6510 cycles / frame becomes available for the CPU.)

### Mode 001 : 640x200 16 color

Base Pointer    | Description                                     | Range             | Restrictions
----------------|-------------------------------------------------|-------------------|--------------
CHAR_PIXEL_BASE | Unused                                          |                   |
MATRIX_BASE     | Points to a 16k block 640x200 pixel data        | XXXXXX00-XXXXXX11 |
COLOR_BASE      | Points to a 2k block for 80x25 color matrix     | XXXX0000-XXXX1111 | lower 32k only

    Pixel data represents either forground color (determined by cell color) or background color. One
    byte is fetched each half cycle giving 80 bytes per line.

    FVC (14 bit counter)
    Color Fetch Addr (15): COLOR_BASE(4) | VC(11)
    Pixel Fetch Addr (16): MATRIX_BASE[1:0](2) | FVC

### Mode 010 : 320x200 16 color

Base Pointer    | Description                                     | Range             | Restrictions
----------------|-------------------------------------------------|-------------------|--------------
CHAR_PIXEL_BASE | Unused                                          |                   |
MATRIX_BASE     | Points to a 32k block 320x200 packed pixel data | XXXXXXX0-XXXXXXX1 |
COLOR_BASE      | Unused                                          |                   |

    Two bytes are fetched each half cycle giving 160 bytes each line. But each pixel color is
    defined by a nibble (16 colors) so we get 2 pixels per byte, or 320 pixels each line.

    FVC (15 bit counter)
    Pixel Fetch Addr (16) : MATRIX_BASE[0](1) | HVC

### Mode 011 : 640x200 4 color

Base Pointer    | Description                                     | Range             | Restrictions
----------------|-------------------------------------------------|-------------------|--------------
CHAR_PIXEL_BASE | Unused                                          |                   |
MATRIX_BASE     | Points to a 32k block 640x200 packed pixel data | XXXXXXX0-XXXXXXX1 |
COLOR_BASE      | Color bank                                      | XXXXXX00-XXXXXX11 |

    Two bytes are fetched each half cycle giving 160 bytes each line. But each pixel color is
    defined by a 2 adjacent bits (4 colors), so we get 4 pixels per byte, or 640 pixels each line.
    The bank of 4 colors within the available 16 are determined by the lower 2 bits of COLOR_BASE.

    HVC (15 bit counter)
    Pixel Fetch Addr (16) : MATRIX_BASE[0](1) | HVC

### Mode 100 : 160x200 16 color

Base Pointer    | Description                                     | Range             | Restrictions
----------------|-------------------------------------------------|-------------------|--------------
CHAR_PIXEL_BASE | Unused                                          |                   |
MATRIX_BASE     | Points to a 16k block 160x200 pixel data        | XXXXXX00-XXXXXX11 |
COLOR_BASE      | Unused                                          |                   |

    One byte is fetched each cycle giving 80 bytes each line. But each pixel color is
    defined by a nibble (16 colors) so we get 2 pixels per byte, or 160 pixels each line.
    byte is fetched each half cycle giving 80 bytes per line.

    FVC (14 bit counter)
    Pixel Fetch Addr (16): MATRIX_BASE[1:0](2) | FVC

## Accessing Video Memory

### Writing to video memory from main DRAM using auto increment

    LDA <ADDR
    STA VIDEO_MEM_1_HI
    LDA >ADDR
    STA VIDEO_MEM_1_LO
    LDA #1               ; Auto increment port 1
    STA VIDEO_MEM_FLAGS
    LDA #$55
    STA VIDEO_MEM_A_VAL  ; write $55 to video mem ADDR

    Sequential writes will auto increment the address:

    LDA #$56
    STA VIDEO_MEM_A_VAL  ; write $56 to ADDR+1
    LDA #$57
    STA VIDEO_MEM_A_VAL  ; write $57 to ADDR+2
    (...etc)

    * video mem hi/lo pairs will wrap as expected

### Reading from video memory into main DRAM using auto increment

    LDA <ADDR
    STA VIDEO_MEM_1_HI
    LDA >ADDR
    STA VIDEO_MEM_1_LO
    LDA #1               ; Auto increment port 1
    STA VIDEO_MEM_FLAGS
    LDA VIDEO_MEM_A_VAL  ; read the value

    Sequential reads will auto increment the address:

    LDA VIDEO_MEM_A_VAL ; read from ADDR+1
    LDA VIDEO_MEM_A_VAL ; read from ADDR+2
    (...etc)

    * video mem hi/lo pairs will wrap as expected

### Performing a move within video memory (CPU)

Here is an example of moving memory within video RAM using the CPU.
(A much more efficient way using block copy is shown below).

    LDA <SRC_ADDR
    STA VIDEO_MEM_1_HI
    LDA >SRC_ADDR
    STA VIDEO_MEM_1_LO

    LDA <DEST_ADDR
    STA VIDEO_MEM_2_HI
    LDA >DEST_ADDR
    STA VIDEO_MEM_2_LO

    LDA #5               ; Auto increment port 1 and 2
    STA VIDEO_MEM_FLAGS

    LDA VIDEO_MEM_A_VAL  ; read from src
    STA VIDEO_MEM_B_VAL  ; write to dest

    Sequential read/writes will auto increment/decrement the address as above.

### Using video mem pointers with an index

Sometimes, it may be more convenient to use an index when porting code to use VIC-II Kawari extended video memory.  This is useful if replacing indirect indexed addressing.

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
    STA VIDEO_MEM_1_LO
    LDA #04
    STA VIDEO_MEM_1_HI
    STY VIDEO_MEM_1_IDX
    LDA VIDEO_MEM_1_VAL

NOTE: VIDEO_MEM_?_IDX only applies to RAM access, not the extended register
      overlay area between 0x00 - 0xff described below.

## DMA Functions

You can perform high speed copy/fill operations by setting the vmem port 1 and 2 functions to DMA. NOTE: Both port 1 and 2 must be configured for DMA.

Register       | Meaning
---------------|--------------
VIDEO_MEM_1_LO | Dest Lo Byte
VIDEO_MEM_1_HI | Dest Hi Byte
VIDEO_MEM_2_LO | Src Lo Byte
VIDEO_MEM_2_HI | Src Hi Byte
VIDEO_MEM_1_IDX | Num Bytes Lo (Copy)
VIDEO_MEM_2_IDX | Num Bytes Hi (Copy)
VIDEO_MEM_1_VAL | Perform DMA Function (on write)
VIDEO_MEM_2_VAL | Unused

Perform DMA Function Value| Meaning
--------------------------|--------------
1  | Copy VMEM src to VMEM dest (start to end)
2  | Copy VMEM src to VMEM dest (end to start)
4  | Fill VMEM dest (See below)
8  | Copy DRAM src\* to VMEM dest
16 | Copy VMEM src to DRAM dest\*
32 | Set Blit Src Info
64 | Set Blit Dst Info & Execute
128| Unused

\* The upper 2 bits of all DRAM src/dest addresses are controlled by the CIA chip. That is, DRAM accesses for DMA transfers will point to the same 16k bank the CIA chip points the VIC to. The upper two bits of all DRAM addresses specified in the registers above are effectively ignored.

### DMA IRQ (firmware 1.16 or higher)

When extra registers are enabled, an additional IRQ control bit is available in 0xD01A and status bit in 0xD019 (firmware v1.16 or higher). Enabling the control bit 4 (value 16) will raise an interrupt with the CPU and the interrupt routine located at $314/$315 will be executed.  Clear the interrupt by writing bit 4 (16) to the IRQST register as you would other types of interrupts.

This is an alternative method for detecting when the DMA operation is complete. It avoids polling which can waste CPU cycles that could used for other operations while the DMA transfer is in progress.  The polling method is used in samples below.  However, the IRQ method is more flexible as you are able to chain multiple DMA operations together with no wasted CPU cycles.

Register | Name | 7 | 6 | 5 | 4  | 3 |  2 |  1 | 0
---------|------|---|---|---|----|---|----|----|---
D019     |IRQST |IRQ|   |   |IDMA|ILP|IMMC|IMBC|IRST
D01A     |IRQEN |   |   |   |EDMA|ELP|EMMC|EMBC|ERST

### VMEM to VMEM Copy Example (DMA)

        LDA <SRC_ADDR
        STA VIDEO_MEM_1_HI
        LDA >SRC_ADDR
        STA VIDEO_MEM_1_LO

        LDA <DEST_ADDR
        STA VIDEO_MEM_2_HI
        LDA >DEST_ADDR
        STA VIDEO_MEM_2_LO

        LDA #15               ; Port 1 copy src, Port 2 copy dest
        STA VIDEO_MEM_FLAGS

        LDA #00
        STA VIDEO_MEM_1_IDX
        LDA #02
        STA VIDEO_MEM_2_IDX   ; 512 bytes

        LDA #1
        STA VIDEO_MEM_1_VAL   ; Perform copy (start to end)

    polldone
        LDA VIDEO_MEM_2_IDX   ; wait for done
        bne polldone

* Copy is finished when VIDEO_MEM_1_IDX == 0 && VIDEO_MEM_2_IDX == 0
* These values do not change while copy is performed so just checking
  one value that started as not 0 for 0 is sufficient to indicate done.
* 8 bytes are moved each 6510 cycle.
* Max copy is 65535 bytes

The following table estimates the number of bytes that can be moved
if move operations are restricted to non-graphics raster lines. (NOTE:
move can be invoked any time.)

Chip    | Non visible gfx lines | Cycles / line | Bytes Copied / Frame
--------|-----------------------|---------------|---------------------
6569    | (312-200) = 112       | 63            | 63\*112\*8 = 56448
6567R8  | (262-200) = 62        | 65            | 65\*62\*8 = 32240
6567R56A| (261-200) = 61        | 64            | 64\*61\*8 = 31232

### VMEM Fill (DMA)

Register       | Meaning
---------------|--------------
VIDEO_MEM_1_LO | Start Lo Byte
VIDEO_MEM_1_HI | Start Hi Byte
VIDEO_MEM_1_IDX | Num Bytes Lo
VIDEO_MEM_2_IDX | Num Bytes Hi
VIDEO_MEM_2_LO  | Byte for fill
VIDEO_MEM_2_HI  | Unused
VIDEO_MEM_1_VAL | 4 = Perform fill with byte stored in VIDEO_MEM_2_LO
VIDEO_MEM_2_VAL | Unused

### Fill Example

        LDA <DST_ADDR
        STA VIDEO_MEM_1_HI
        LDA >DST_ADDR
        STA VIDEO_MEM_1_LO

        LDA #15               ; Port 1 DMA, Port 2 DMA
        STA VIDEO_MEM_FLAGS

        LDA #00
        STA VIDEO_MEM_1_IDX
        LDA #02
        STA VIDEO_MEM_2_IDX   ; 512 bytes

        LDA #ff               ; Byte for fill
        STA VIDEO_MEM_2_LO

        LDA #4
        STA VIDEO_MEM_1_VAL   ; Perform fill

    polldone
        LDA VIDEO_MEM_2_IDX   ; wait for done
        bne polldone

* Fill is finished when VIDEO_MEM_1_IDX == 0 && VIDEO_MEM_2_IDX == 0
* These values do not change while copy is performed so just checking
  one value that started as not 0 for 0 is sufficient to indicate done.
* 32 bytes are filled each 6510 cycle.
* Max fill is 65535 bytes

The following table estimates the number of bytes that can be filled
if fill operations are restricted to non-graphics raster lines. (NOTE:
fill can be invoked any time.)

Chip    | Non visible gfx lines | Cycles / line | Bytes Filled / Frame
--------|-----------------------|---------------|---------------------
6569    | (312-200) = 112       | 63            | 63\*112\*32 = 225792
6567R8  | (262-200) = 62        | 65            | 65\*62\*32 = 128960
6567R56A| (261-200) = 61        | 64            | 64\*61\*32 = 124928

### DRAM to VMEM copy example (DMA)

        LDA <VMEM_SRC_ADDR  ; vmem src
        STA VIDEO_MEM_1_HI
        LDA >VMEM_SRC_ADDR
        STA VIDEO_MEM_1_LO

        LDA <DRAM_DST_ADDR  ; dram dest
        STA VIDEO_MEM_2_HI
        LDA >DRAM_DST_ADDR
        STA VIDEO_MEM_2_LO

        LDA #0
        STA VIDEO_MEM_1_IDX
        LDA #4
        STA VIDEO_MEM_2_IDX ; size 2k

        LDA #15               ; Port 1 op DMA, Port 2 op DMA
        STA VIDEO_MEM_FLAGS

        LDA #8                ; Perform DMA op 
        STA VIDEO_MEM_FLAGS

    polldone
        LDA VIDEO_MEM_2_IDX   ; wait for done
        bne polldone

### VMEM to DRAM copy example (DMA)

        LDA <DRAM_SRC_ADDR  ; dram src
        STA VIDEO_MEM_1_HI
        LDA >DRAM_SRC_ADDR
        STA VIDEO_MEM_1_LO

        LDA <VMEM_DST_ADDR  ; vmem dest
        STA VIDEO_MEM_2_HI
        LDA >VMEM_DST_ADDR
        STA VIDEO_MEM_2_LO

        LDA #0
        STA VIDEO_MEM_1_IDX
        LDA #4
        STA VIDEO_MEM_2_IDX   ; size 2k

        LDA #15               ; Port 1 op DMA, Port 2 op DMA
        STA VIDEO_MEM_FLAGS

        LDA #16               ; Perform DMA op 
        STA VIDEO_MEM_FLAGS

    polldone
        LDA VIDEO_MEM_2_IDX   ; wait for done
        bne polldone

* VIC-II Kawari uses idle graphics fetch cycles (as well as idle cycles) to perform DRAM to VMEM or VMEM to DRAM transfers. On raster lines less than 51 and greater than 250 (i.e when graphics fetches are in idle state), at least 40 bytes will be transfered each raster line. The actual number depends on the chip model since there are 2-4 additional idle cycles. When graphics fetches are not in idle state (i.e. usually in the visible gfx region) only 2-4 bytes are transfered each raster line.  Rough calculations on the number of bytes that can be transfered per second are provided below.

Chip    | Idle RL             | Active RL | Bytes/Idle RL | Bytes/Active RL| Bytes / Frame 
--------|---------------------|-----------|---------------|----------------|---------------
6569    | 50 + (312-250) = 112| 200       | 42            | 2              | 5104
6567R8  | 50 + (262-250) = 62 | 200       | 44            | 4              | 3528          
6567R56A| 50 + (261-250) = 61 | 200       | 43            | 3              | 3223          

* If badlines are suppressed (i.e turn off the den bit), then all raster lines can transfer the maximum number of bytes and the transfer rate is much higher.  By turning off the low-res VIC modes, transferring memory from DRAM to VMEM can be as high as 13k/Frame.

## Blitter

The blitter modifies graphics data in a region of video memory (dest) using data in another region of video memory (source) according to the specified operation (rasterOp).  Video mem flags for both ports 1 & 2 functions must be set to DMA (3) for the blitter to execute. The blitter only operates on the extended video ram (VRAM), not DRAM.

The base pointer for the source and destination must be specified as well as the source and destination stride. The source and destination coordinates (x,y) of a rectangle (w,h) must also be specified.  For both 320x200x16 and 640x200x4 resolutions, the stride is 160.  However, you can keep an off-screen bitmap of any stride if needed. It is up to the caller to ensure the stride is sufficient to contain the width of the rectangle. Pixel depth is always determined by the current resolution in VIDEO_MODE1 (bits 6-7). The blitter only works with bitmap modes 320x200 or 640x200.  Using the blitter with other modes is undefined behavior.  The caller may check 0xd03c == 0 to determine whether the blitter operation is complete.

### Operating the blitter is as follows:

1. Set the blitter source rectangle information
2. Set the blitter destination rectangle information, raster operation + flags and execute
3. Check 0xd03d == 0 for done (or use IRQ - v1.16+)

### Setting Blitter Source Info

Register| Param | Description
--------|-------|------------
0xd02f | Width Hi | The rectangle width hi byte (only lowest 2 bits are valid)
0xd030 | Width Lo | The rectangle width lo byte
0xd031 | Height Hi | The rectangle height hi byte (only lowest 2 bits are valid)
0xd032 | Height Lo  | The rectangle height lo byte
0xd035 | Src Ptr Lo Byte | The base pointer to bitmap data (lo byte)
0xd036 | Src Ptr Hi byte | The base pointer to bitmap data (hi byte)
0xd039 | Src X Lo Byte | The x coordinate for the rectangle (lo byte)
0xd03a | Src X Hi Byte | The x coordinate for the rectangle (hi byte)
0xd03b | Src Y Lo Byte | The y coordinate for the rectangle
0xd03c | Src Stride | The source bitmap stride
0xd03d | Set | Set blitter src with value of 32

### Setting Blitter Dest Info & Execute

Register| Param | Description
--------|-------|------------
0xd02f | Blit Flags | Flags and Raster operation (See below)
0xd030 | Unused |
0xd031 | Unused | 
0xd032 | Unused | 
0xd035 | Dst Ptr Lo Byte | The base pointer to bitmap data (lo byte)
0xd036 | Dst Ptr Hi byte | The base pointer to bitmap data (hi byte)
0xd039 | Dst X Lo Byte | The x coordinate for the rectangle (lo byte)
0xd03a | Dst X Hi Byte | The x coordinate for the rectangle (hi byte)
0xd03b | Dst Y Lo Byte | The y coordinate for the rectangle
0xd03c | Dst Stride | The destination bitmap stride
0xd03d | Set Reg | Set blitter dst and perform blit op with value of 64

### Blitter flags

8765 |4|3|2|1
-----|-|-|-|-
index| transparency bit| raster operation

If set, the transparency bit tells the blitter to consider any pixel with a color index specified by bits 8-5 as transparent.  The raster operation is fixed to DST = SRC in that case.  Note that in 640x400x4 mode, only bits 5&6 matter since ther are only 4 colors per pixel.

### Raster Operations

Value | Description
------|------------
0 | DST = SRC
1 | DST = SRC | DST
2 | DST = SRC & DST
3 | DST = SRC XOR DST
4-7 | Unused

### Additional Notes

There is no clipping of rectangles.  The rectangles must be within the bounds of the bitmap region.

The estimated bandwidth of blitter operations is 4 pixels per 6510 cycle.  The table below shows how many pixels / frame can be copied/movied if blitter operations are restricted to run outside visible graphics region.

Chip    | Non visible gfx lines | Cycles / line | Pixels Moved / Frame
--------|-----------------------|---------------|---------------------
6569    | (312-200) = 112       | 63            | 63\*112\*4 = 28224
6567R8  | (262-200) = 62        | 65            | 65\*62\*4 = 16120
6567R56A| (261-200) = 61        | 64            | 64\*61\*4 = 15616

NOTE: You can invoke the blitter any time and you can likely get a slightly higher bandwidth by starting operations before the raster line reaches the last visible graphics line. However, care must be taken to avoid altering visible graphics region where the scanline currently is to avoid tearing.

## Extra Registers Overlay

When BIT 6 of the VIDEO_MEM_FLAGS register is set, the first 256 bytes of video RAM is mapped to extra registers for special VIC-II Kawari functions.

### All registers

Location | Name | Since | Description | Capability Requirement | Can be saved?
---------|------|-------|-------------|------------------------|---------------------
0x00 - 0x03 | MAGIC BYTES | 1.4 | EEPROM Magic Bytes | N/A | Y
0x04 | DISPLAY_FLAGS | 1.4 | See below | NONE | Y
0x05 | EEPROM_BANK | 1.4 | EEPROM Bank | HAVE_EEPROM | N
0x06 | DISPLAY_FLAGS2 | 1.12 | See below | HAVE_EEPROM | Y
0x07 | CFG_VERSION | 1.12 | See below | HAVE_EEPROM | N
0x1f | CHIP_MODEL | 1.4 | Chip Model Select (0=6567R8, 1=6569R3, 2=6567R56A, 3=6569R1) | NONE | Y
0x20 - 0x3f | UNUSED | 1.4 | Unused | NONE | N/A
0x40 - 0x7f | PAL_RGB | 1.4 | 4x16 array of RGBx (4th byte unused) | CONFIG_RGB | Y
0x80 | BLACK_LEVEL | 1.4 | Composite black level (0-63) | CONFIG_COMPOSITE | Y
0x81 | BURST_AMPLITUDE | 1.4 | Composite color burst amplitude (1-15, 0 = no color burst) | CONFIG_COMPOSITE | Y
0x83 | VERSION | 1.4 | Version (high nibble major, low nibble minor) - Read Only | NONE | N/A
0x85 | CURSOR_LO | 1.4 | Hires Cursor lo byte | HIRES_MODES | N/A
0x86 | CURSOR_HI | 1.4 | Hires Cursor hi byte | HIRES_MODES | N/A
0x87 | CAP_LO    | 1.4 | Capability Bits lo byte (Read Only)| NONE | N/A
0x88 | CAP_HI    | 1.4 | Capability Bits hi byte (Read Only)| NONE | N/A
0x89 | TIMING_CHANGE | 1.4 | HDMI/VGA Timing change signal - Bit 1  | CONFIG_TIMING | N
0x8a - 0x8f | Reserved | 1.4 | Reserved | NONE | N/A
0x90 - 0x9f | VARIANT_NAME | 1.4 | Variant Name | NONE | N/A
0xa0 - 0xaf | LUMA_LEVELS | 1.4 | Composite luma levels for colors (0-63) | CONFIG_COMPOSITE
0xb0 - 0xbf | PHASE_VALUES | 1.4 | Composite phase values for colors (0-255 representing 0-359 degrees) | CONFIG_COMPOSITE | Y
0xc0 - 0xcf | AMPL_VALUES | 1.4 | Composite amplitude values for colors (1-15, 0 = no modulation) | CONFIG_COMPOSITE | Y
0xd0 | VGA_HBLANK | 1.4 | HDMI/VGA NTSC H blank start | CONFIG_TIMING | N
0xd1 | VGA_FPORCH | 1.4 | HDMI/VGA NTSC H front porch | CONFIG_TIMING | N
0xd2 | VGA_SPULSE | 1.4 | HDMI/VGA NTSC H sync pulse | CONFIG_TIMING | N
0xd3 | VGA_BPORCH | 1.4 | HDMI/VGA NTSC H back porch | CONFIG_TIMING | N
0xd4 | VGA_VBLANK | 1.4 | HDMI/VGA NTSC V blank start | CONFIG_TIMING | N
0xd5 | VGA_FPORCH | 1.4 | HDMI/VGA NTSC V front porch | CONFIG_TIMING | N
0xd6 | VGA_SPULSE | 1.4 | HDMI/VGA NTSC V sync pulse | CONFIG_TIMING | N
0xd7 | VGA_BPORCH | 1.4 | HDMI/VGA NTSC V back porch | CONFIG_TIMING | N
0xd8 | VGA_HBLANK | 1.4 | HDMI/VGA PAL H blank start | CONFIG_TIMING | N
0xd9 | VGA_FPORCH | 1.4 | HDMI/VGA PAL H front porch | CONFIG_TIMING | N
0xda | VGA_SPULSE | 1.4 | HDMI/VGA PAL H sync pulse | CONFIG_TIMING | N
0xdb | VGA_BPORCH | 1.4 | HDMI/VGA PAL H back porch | CONFIG_TIMING | N
0xdc | VGA_VBLANK | 1.4 | HDMI/VGA PAL V blank start | CONFIG_TIMING | N
0xdd | VGA_FPORCH | 1.4 | HDMI/VGA PAL V front porch | CONFIG_TIMING | N
0xde | VGA_SPULSE | 1.4 | HDMI/VGA PAL V sync pulse | CONFIG_TIMING | N
0xdf | VGA_BPORCH | 1.4 | HDMI/VGA PAL V back porch | CONFIG_TIMING | N
0xe0 - 0xff |   | UNUSED | Unused | NONE | N/A

### RGB Color Registers (For DVI/VGA)

VIC-II Kawari has a configurable color palette. The 16 colors can be selected from a palette of 262144 colors by specifying three 6-bit RGB values. (The upper 2 bits in each byte are ignored).  The RGB palette is located at 0x40 in the extended registers page.

### HSV Color Registers (For luma/chroma)

Colors generated by the luma/chroma generator can be modified by changing registers 0xa0-0xaf (luma levels), 0xb0-0xbf (hue/phase angles) and 0xc0-0xcf (saturation/amplitude).  Luma levels are 6 bit values (0-63).  Phase angles are 0-255 (representing 0-359 degrees). Amplitudes are 4 bit values (0-15).  (NOTE: Blanking levels below 8 may not be accepted by some TV's/monitors and any color luma value should be at or above the blanking level or the CRT may lose sync.)

#### General Notes

Any register above 0x1f is a 'per-chip' register. If it is persisted to EEPROM, it will be persisted only for the chip specified in eeprom_bank. Any register 0x1f or less is a 'cross-chip' register and will be applied to all chip models at boot.

#### Notes on Timing Registers

NOTE: The RGB based video timing registers are not available in unless the bitstream was generated with configurable timing. This feature was meant to test different values during development and was not meant as an end-user feature. These registers will likely be removed once the final timings are determined.

Blanking start values are absolute values compared to the native resolution.

VBLANK is compared to raster line (vertical) and HBLANK to xpos (horizontal) internal counters.

NTSC HBLANK and VBLANK can range from 0-255

PAL HBLANK start ranges from 0-255

PAL VBLANK start ranges from 256-511 (represented by 0-255)

For VGA, Front Porch, Sync Pulse Width and Back Porch are durations and are added cumulatively to blank start. (Hence, Visible End = Blank Start and Visible Start = Blank Start + Front Porch + Sync Pulse Width + Back Porch)

Care must be taken so that no value exceeds the resolution.  For PAL, VBLANK + FPORCH + SPULSE + is expected to be less than 311 but BPORCH is expected to cross 311.

For composite output, color burst and sync pulses begin/end are hard coded to NTSC or PAL video standards and are relative to blank start.

### Other Registers

DISPLAY_FLAGS| Function
-------------|-------
Bit 1        | Raster lines visible(1) or invisible(0) for RGB/DVI modes
Bit 2        | Use native y resolution for DVI/RGB modes rather than double (1=15khz, 0=31khz)
Bit 3        | Use native x resolution for DVI/RGB modes rather than double (1=native, 0=doubled)
Bit 4        | Enable CSYNC on HSYNC pin (VSYNC held low)
Bit 5        | RGB VSync Polarity (0=active low, 1=active high)
Bit 6        | RGB HSync Polarity (0=active low, 1=active high)
Bit 7        | External switch state (0=not inverting saved chip, 1=inverting saved chip)
Bit 8        | Enable/disable max luma on first pixel for each rasterline (composite out only)

* Double x resolution is required for 80 column mode or any hires mode.
* If CSYNC is enabled, polarity is controlled by HSync Polarity

DISPLAY_FLAGS2| Function
-------------|-------
Bit 1        | NTSC 50 Enable/Disable
Bit 2        | Unused
Bit 3        | Unused
Bit 4        | Unused
Bit 5        | Unused
Bit 6        | Unused
Bit 7        | Unused
Bit 8        | Unused

CAP_LO|Description
------|--------
Bit 1 | Has analog RGB out
Bit 2 | Has digital RGB out (DVI)
Bit 3 | Has composite out (LUMA/CHROMA)
Bit 4 | Has configurable RGB palette
Bit 5 | Has configurable Luma/Chroma/Amplitude
Bit 6 | Has configurable analog/digital RGB timing params
Bit 7 | Has configuration persistance
Bit 8 | Has hires modes available

CAP_HI|Description
------|--------
Bit 1-8 | Reserved

### Variant Name

The extra register overlay area 0x0090 - 0xd09f is used to identify the Kawari variant name. This is a max 16 byte null terminated PETSCII string.  All forks should change this to something other than 'main' if they plan on releasing a bitstream. See [FORKING.md](FORKING.md)

## Notes

The extra registers described here should remain functional across all VIC-II Kawari variants. This way, the main branch configuration utility will be able to at least query the variant name and version on any variant (as well as change video standard or other common features between variants).  Users will be able to at least identify what variant they are running even if they use the main branch config utility.  Also, programs can run a simple check routine that will run on all variants and can display a user friendly message indicating the wrong variant is installed.

# Notation

Bit   | Description | Value
------|-------------|------
Bit 1 | LSB | 1
Bit 2 |  | 2
Bit 3 |  | 4
Bit 4 |  | 8
Bit 5 |  | 16
Bit 6 |  | 32
Bit 7 |  | 64
Bit 8 | MSB | 128
