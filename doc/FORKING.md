Back to [README.md](../README.md)

# VIC-II Kawari Forking Guide

## What do I need to know about forking VIC-II Kawari?

The VIC-II Kawari project supports developers who want to alter VIC-II Kawari to provide new features or interesting extensions. If you do plan on forking VIC-II Kawari, we ask that you follow this guide so that users who install your fork can use the upstream config utility to at least display the variant name and version.

We ask that all forks do the following:

1. Keep the extra register activation [REGISTERS.md](REGISTERS.md) (i.e POKEing "VIC2" into 0x3f) functional along with the 'reserved' 0x3b-0x3f extra mem access mechanism. The extra mem registers 0x83 (VERSION), 0x90-0x9f (VARIANT) should also remain functional. This will allow a single upstream configuration utilty to successfully talk to your variant and at least display the variant name and its version. You are free to use an additional extra register activation sequence for your own scheme.

2. The format for build strings is:

    <BRANCH><BOARD>[-SUBVARIANT]

    BRANCH must be 4 characters. i.e. MAIN
    BOARD must be 2 characters. i.e. LH
    SUBVARIANT can be up 4 chars (plus 1 for the dash) and is optional. i.e. -DOTC

Replace the 4 character variant BRANCH with your own unique string. This can be any name you wish as long as you do not use the reserved 'MAIN'.  This value will be displayed to users by the configuration utility. It will point users to your fork where they can find a custom config utility for your variant (if needed). 
Board codes are:
    No suffix = beta board
    LH = Trion Mini
    LG = Trion Large
    LD = Spartan Large

3. Forks should only release 'multiboot' images,  never 'golden' images.  The 'golden' image is the fallback image that will boot if the active image should fail.

## Variant Identifier

The variant identifier is defined in each config.vh.\* file.  Your fork should change the PETSCII values for the prefix (which MUST be 4 characters). MAIN is a reserved branch name. The 5th and 6th characters must match the board version LD (large spartan), LH (Trion Mini) or LG (Trion Large).

## Versioning

You should probably version your fork separately from the main version to avoid confusion.

## Do I have to maintain backwards compatibility with the VICII?

No. It's your fork. You can do whatever you want. You can design a new graphics chip that is completely incompatible with the 6567/6569 chips if you want.

## Can my feature be upstreamed into the official variant?

If your feature is a good fit for being upstreamed, it will be considered. Bug fixes should almost always be upstreamed so if you find any, please submit a pull request with a good description of the issue and the fix.

## What are some things I can do in my fork?

THe main Kawari releases use almost all of the available resources on the FPGA. However, if you remove some mainline features, there is room for some experimentation.  Here are some possibilities:

1. Add a display address translator (DAT)

   Provide a convenient x,y coordinate to memory location & bit function for different graphics modes so the CPU doesn't have to make those computations.  This can make for much faster drawing routines.

2. Add extra sprites

   Add a sprite bank register to multiplex in more than 8 sprites.

3. Larger sprites/wider character cells

   It might be possible to fetch more than one byte inside a half cycle if using 150ns or 120ns RAM.  Some RAM chips have page modes where you can keep the same row address while strobing in successive column addresses too.

4. Add a new video mode/more colors/half brightness mode

   Turn one or more of the legacy 'illegal' video modes into a working mode. There are some unused bits in certain modes which could be repurposed (brightness levels, for example).  You could also extend the hires pixel sequencer registers to 8 bits from 4 and add a 256 indexed color mode.

5. Use idle cycles to execute instructions

   Instead of executing idle cycles and throwing away the bytes read, use those cycles for extra some processing.

6. Add another processor

   Add another processor core. It may have to block on memory read/write until an idle cycle or unused sprite dma cycle is reached.  The addressable range would be limited to 16k and be confined to the same bank as the VIC but this could be interesting.

7. Write to memory from the VIC

   A real VICII chip cannot write to memory since it can't set the WR line LOW.  VIC-II Kawari, however, can set WR LOW so this is theoretically possible.  Using idle cycles to execute instructions and write to DRAM (limited to 16k bank) should be possible.

8. Use the upper 1Mb of flash space as a drive

  The flash chip's upper 1Mb of space is unused and can be written to/read from in 16k blocks by the 6510 (provided the SPI functions are not locked).  It might be possible to turn that space into a drive and use a custom loader.

9. Repurpose the NTSC/PAL switch into a reset

  After the device has booted, the physical NTSC/PAL has no use.  It could be used to reset the 6510 since Kawari can drive the RESET line low.

