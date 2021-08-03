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
0xd02f |      | Reserved
0xd030 |      | Reserved
0xd031 |      | Reserved
0xd032 |      | Reserved
0xd033 |      | Reserved
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

## SPI Programming Register / Status Register ($d034)

This register is used by config/flash programs to update the FPGA bitstream.

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

On Read:

Bit          | Bit 8=0
-------------|---------
Bit 1        | Spi Data In Line
Bit 2        | Bulk Flash Operation Busy
Bit 3        | Bulk Flash Operation Verify Error
Bit 4        | Persistence Lock Status
Bit 5        | Extensions Lock Status
Bit 6        | SPI Lock Status
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

VIC-II Kawari adds 32k of video memory to the C64. This memory can be directly accessed by VIC-II Kawari for new graphics modes and indirectly by the 6510 CPU. The registers 0xd039-0xd03f are used to read/write from/to video memory. (This space can also be used to store code but it would have to be copied back to main memory to be executed by the CPU.)

VIDEO_MEM_FLAGS | Description
----------------|-------------
BIT 1,2  | PORT 1 FUNCTION <br>0=NONE<br>1=AUTO INC<br>2=AUTO DEC<br>3=COPYSRC/FILL
BIT 3,4  | PORT 2 FUNCTION <br>0=NONE<br>1=AUTO INC<br>2=AUTO DEC<br>3=COPYDST/FILLVAL
BIT 5    | Persist busy status flag (see below)
BIT 6    | Extra 256 registers overlay at 0x0000 Enable/Disable
BIT 7    | Persist Flag (see below)
BIT 8    | Deactivate Extra Registers

When BIT 7 is 1, changes to some registers (like color palette, composite luma, phase, amplitude, etc) will be persisted to the EEPROM and restored on reboot. Each register change must be written to the EEPROM which may not be able to keep up with many register changes back to back. To avoid lost changes, the 6502 should check BIT 5 and make sure it is 0 before attempting to set the next register. For boards that do not support persistence, BIT 7 has no function and BIT 5 is always 0.  If BIT 7 is not enabled, BIT 5 can be ignored.

VIDEO_MODE1 | Description
------------|------------
BIT 1-3     | CHAR_PIXEL_BASE
BIT 4       | UNUSED
BIT 5       | HIRES ENABLE
BIT 6-7     | HIRES MODE (0=TEXT, 1=640x200, 2=320x200, 3=640x200)
BIT 8       | UNUSED

VIDEO_MODE2 | Description
------------|------------
BIT 1-4     | MATRIX_BASE
BIT 4-8     | COLOR_BASE

## Color Memory
For the 80 column text mode, each byte stores color information as well as display attributes.

BIT        | Description
-----------|-------------
0-3        | 16 color index
4          | blink (every 32 frames)
5          | underscore
6          | reverse video
7          | alt char set

## Hires Enable
This bit must be 1 for any of the hi-resolution modes to be visible.  When enabled, badlines normally generated by the 40 column mode are disabled (as though the DEN bit is set to 0).

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

    Sequential writes will auto increment the address:

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

Here is an example of moving memory within video RAM using the CPU.
(A much more efficient way using block copy is shown below).

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

## Block Copy

You can perform high speed block copy operations by setting the vmem port 1 and 2 functions to COPYSRC/FILL and COPYDST/FILLVAL respectively. NOTE: Both port 1 and 2 must be configured for COPY/FILL function.

Register       | Meaning
---------------|--------------
VIDEO_MEM_1_LO | Dest Lo Byte
VIDEO_MEM_1_HI | Dest Hi Byte
VIDEO_MEM_2_LO | Src Lo Byte
VIDEO_MEM_2_HI | Src Hi Byte
VIDEO_MEM_1_IDX | Num Bytes Lo
VIDEO_MEM_2_IDX | Num Bytes Hi
VIDEO_MEM_1_VAL | Perform Copy, 1=copy start to end, 2=copy end to start
VIDEO_MEM_2_VAL | Unused

### Copy Example

        LDA <SRC_ADDR
        STA VIDEO_MEM_A_HI
        LDA >SRC_ADDR
        STA VIDEO_MEM_A_LO

        LDA <DEST_ADDR
        STA VIDEO_MEM_B_HI
        LDA >DEST_ADDR
        STA VIDEO_MEM_B_LO

        LDA #15               ; Port 1 copy src, Port 2 copy dest
        STA VIDEO_MEM_FLAGS

        LDA #00
        STA VIDEO_MEM_1_IDX
        LDA #02
        STA VIDEO_MEM_2_IDX   ; 512 bytes

        LDA #1
        STA VIDEO_MEM_1_VAL   ; Perform copy (start to end)

    waitdone
        LDA VIDEO_MEM_2_IDX   ; wait for done
        bne waitdone

* Copy is finished when VIDEO_MEM_1_IDX == 0 && VIDEO_MEM_2_IDX == 0
* These values do not change while copy is performed so just checking
  one value that started as not 0 for 0 is sufficient to indicate done.
* 8 bytes are moved each 6510 cycle.
* Max copy is 65535 bytes

## Block Fill

You can perform high speed block fill operations by setting the vmem port 1 and 2 functions to COPYSRC/FILL and COPYDST/FILLVAL respectively.

### Fill

Register       | Meaning
---------------|--------------
VIDEO_MEM_1_LO | Start Lo Byte
VIDEO_MEM_1_HI | Start Hi Byte
VIDEO_MEM_1_IDX | Num Bytes Lo
VIDEO_MEM_2_IDX | Num Bytes Hi
VIDEO_MEM_2_LO  | Byte for fill
VIDEO_MEM_2_HI  | Unused
VIDEO_MEM_1_VAL | 4 = Perform fill with byte stored in VIDEO_MEM_2_VAL
VIDEO_MEM_2_VAL | Unused

### Fill Example

        LDA <DST_ADDR
        STA VIDEO_MEM_A_HI
        LDA >DST_ADDR
        STA VIDEO_MEM_A_LO

        LDA #15               ; Port 1 fill dst, Port 2 fill val
        STA VIDEO_MEM_FLAGS

        LDA #00
        STA VIDEO_MEM_1_IDX
        LDA #02
        STA VIDEO_MEM_2_IDX   ; 512 bytes

        LDA #ff               ; Byte for fill
        STA VIDEO_MEM_2_LO

        LDA #4
        STA VIDEO_MEM_1_VAL   ; Perform fill

    waitdone
        LDA VIDEO_MEM_2_IDX   ; wait for done
        bne waitdone

* Fill is finished when VIDEO_MEM_1_IDX == 0 && VIDEO_MEM_2_IDX == 0
* These values do not change while copy is performed so just checking
  one value that started as not 0 for 0 is sufficient to indicate done.
* 32 bytes are filled each 6510 cycle.
* Max fill is 65535 bytes

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
    STA VIDEO_MEM_A_LO
    LDA #04
    STA VIDEO_MEM_A_HI
    STY VIDEO_MEM_A_IDX
    LDA VIDEO_MEM_A_VAL

NOTE: VIDEO_MEM_?_IDX only applies to RAM access, not the extended register
      overlay area between 0x00 - 0xff described below.

### Extra Registers Overlay

When BIT 6 of the VIDEO_MEM_FLAGS register is set, the first 256 bytes of video RAM is mapped to extra registers for special VIC-II Kawari functions.

### All registers

Location | Name | Description | Capability Requirement | Can be saved?
---------|------|-------------|------------------------|---------------------
0x00 - 0x03 | MAGIC BYTES | EEPROM Magic Bytes | N/A | Y
0x04 | DISPLAY_FLAGS | See below | NONE | Y
0x05 | EEPROM_BANK | EEPROM Bank | HAVE_EEPROM | N
0x1f | CHIP_MODEL | Chip Model Select (0=6567R8, 1=6569R3, 2=6567R56A, 3=6569R1) | NONE | Y
0x20 - 0x3f | UNUSED | Unused | NONE | N/A
0x40 - 0x7f | PAL_RGB | 4x16 array of RGBx (4th byte unused) | CONFIG_RGB | Y
0x80 | BLACK_LEVEL | Composite black level (0-63) | CONFIG_COMPOSITE | Y
0x81 | BURST_AMPLITUDE | Composite color burst amplitude (1-15, 0 = no color burst) | CONFIG_COMPOSITE | Y
0x83 | VERSION | Version (high nibble major, low nibble minor) - Read Only | NONE | N/A
0x85 | CURSOR_LO | Hires Cursor lo byte | HIRES_MODES | N/A
0x86 | CURSOR_HI | Hires Cursor hi byte | HIRES_MODES | N/A
0x87 | CAP_LO    | Capability Bits lo byte (Read Only)| NONE | N/A
0x88 | CAP_HI    | Capability Bits hi byte (Read Only)| NONE | N/A
0x89 | TIMING_CHANGE | HDMI/VGA Timing change signal - Bit 1  | CONFIG_TIMING | N
0x8a - 0x8f | Reserved | Reserved | NONE | N/A
0x90 - 0x9f | VARIANT_NAME | Variant Name | NONE | N/A
0xa0 - 0xaf | LUMA_LEVELS | Composite luma levels for colors (0-63) | CONFIG_COMPOSITE
0xb0 - 0xbf | PHASE_VALUES | Composite phase values for colors (0-255 representing 0-359 degrees) | CONFIG_COMPOSITE | Y
0xc0 - 0xcf | AMPL_VALUES | Composite amplitude values for colors (1-15, 0 = no modulation) | CONFIG_COMPOSITE | Y
0xd0 | VGA_HBLANK | HDMI/VGA NTSC H blank start | CONFIG_TIMING | N
0xd1 | VGA_FPORCH | HDMI/VGA NTSC H front porch | CONFIG_TIMING | N
0xd2 | VGA_SPULSE | HDMI/VGA NTSC H sync pulse | CONFIG_TIMING | N
0xd3 | VGA_BPORCH | HDMI/VGA NTSC H back porch | CONFIG_TIMING | N
0xd4 | VGA_VBLANK | HDMI/VGA NTSC V blank start | CONFIG_TIMING | N
0xd5 | VGA_FPORCH | HDMI/VGA NTSC V front porch | CONFIG_TIMING | N
0xd6 | VGA_SPULSE | HDMI/VGA NTSC V sync pulse | CONFIG_TIMING | N
0xd7 | VGA_BPORCH | HDMI/VGA NTSC V back porch | CONFIG_TIMING | N
0xd8 | VGA_HBLANK | HDMI/VGA PAL H blank start | CONFIG_TIMING | N
0xd9 | VGA_FPORCH | HDMI/VGA PAL H front porch | CONFIG_TIMING | N
0xda | VGA_SPULSE | HDMI/VGA PAL H sync pulse | CONFIG_TIMING | N
0xdb | VGA_BPORCH | HDMI/VGA PAL H back porch | CONFIG_TIMING | N
0xdc | VGA_VBLANK | HDMI/VGA PAL V blank start | CONFIG_TIMING | N
0xdd | VGA_FPORCH | HDMI/VGA PAL V front porch | CONFIG_TIMING | N
0xde | VGA_SPULSE | HDMI/VGA PAL V sync pulse | CONFIG_TIMING | N
0xdf | VGA_BPORCH | HDMI/VGA PAL V back porch | CONFIG_TIMING | N
0xe0 - 0xff | UNUSED | Unused | NONE | N/A

### RGB Color Registers (For DVI/VGA)

VIC-II Kawari has a configurable color palette. The 16 colors can be selected from a palette of 262144 colors by specifying three 6-bit RGB values. (The upper 2 bits in each byte are ignored).  The RGB palette is located at 0x00 in the extended registers page.

### HSV Color Registers (For luma/chroma)
Colors generated by the luma/chroma generator can also be modified by changing registes 0xa0-0xaf (luma levels), 0xb0-0xbf (hue/phase angles) and 0xc0-0xcf (saturation/amplitude).  Luma levels are 6 bit values (0-63).  Phase angles are 0-255 (representing 0-359 degrees). Amplitudes are 4 bit values (0-15).  (NOTE: Blanking levels below 8 may not be accepted by some TV's/monitors and any color luma value should be at or above the blanking level or the monitor may lose sync.)

#### General Notes

Any register above 0x1f is a 'per-chip' register. If it is persisted to EEPROM, it will be persisted only for the chip specified in eeprom_bank. Any register 0x1f or less is a 'cross-chip' register and will be applied to all chip models at boot.

#### Notes on Timing Registers

Blanking start values are absolute values compared to the native resolution.

VBLANK is compared to raster line (vertical) and HBLANK to xpos (horizontal) internal counters.

NTSC HBLANK and VBLANK can range from 0-255

PAL HBLANK start ranges from 0-255

PAL VBLANK start ranges from 256-511 (represented by 0-255)

For VGA, Front Porch, Sync Pulse Width and Back Porch are durations and are added cumulatively to blank start. (Hence, Visible End = Blank Start and Visible Start = Blank Start + Front Porch + Sync Pulse Width + Back Porch)

Care must be taken so that no value exceeds the resolution.  For PAL, VBLANK + FPORCH + SPULSE + is expected to be less than 311 but BPORCH is expected to cross 311.

For composite output, color burst and sync pulses begin/end are hard coded to NTSC or PAL video standards and are relative to blank start.

DISPLAY_FLAGS| Function
-------------|-------
Bit 1        | Raster lines visible(1) or invisible(0) for RGB/DVI modes
Bit 2        | Use native y resolution for DVI/RGB modes rather than double (1=15khz, 0=31khz)
Bit 3        | Use native x resolution for DVI/RGB modes rather than double (1=native, 0=doubled)
Bit 4        | Enable CSYNC on HSYNC pin (VSYNC held low)
Bit 5        | RGB VSync Polarity (0=active low, 1=active high)
Bit 6        | RGB HSync Polarity (0=active low, 1=active high)
Bit 7        | External switch state (0=not inverting saved chip, 1=inverting saved chip)
Bit 8        | Reserved

* Double x resolution is required for 80 column mode or any hires mode.
* If CSYNC is enabled, polarity is controlled by HSync Polarity

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
