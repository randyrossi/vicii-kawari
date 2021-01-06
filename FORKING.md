# VICII-Kawari Forking Guide

## What do I need to know about forking VICII-Kawari?

The VICII-Kawari project supports developers who want to alter VICII-Kawari to provide new features or interesting extensions. If you do plan on forking VICII-Kawari, we ask that you follow this guide so that users who install your fork can use the upstream config utility to at least display the variant name, version and capability strings your variant offers.

We ask that all forks do the following:

1. Keep the extra register activation [REGISTERS.md](REGISERS.md) (i.e POKEing "VIC2" into 0x3f) functional along with the 'reserved' 0x3b-0x3f extra mem access mechanism. The extra mem registers 0x00-0x5f should also remain functional. This will allow a single upstream configuration utilty to successfully talk to your variant and at least display your variant name, its version and capability strings. You are free to use an additional extra register activation sequence for your own scheme if you wish.

2. Replace the 'official' variant identifier with your own unique string. This can be any name you wish as long as you do not use the word 'official'.  This value will be displayed to users by the configuration utility. It will point users to your fork where they can find a custom config utility for your variant (if needed).

3. Add any capability strings for new features your variant may add. For example, if your fork adds a math co-processor, you can add "MATHCO".  This will let the config utility display the extensions you've added.  It can also be used by programs to detect features.  So, in theory, a regular C64 program could detect the presence of a math co-processor and use different code to take advantage of that feature.

## Variant Identifier

The variant identifier is found in registers.v file.  Your fork should change this value.

## Capability descriptions

The capability strings are found in capabilities.v. It is recommended you provide a short string that will identify the extensions your fork has added.

## Versioning

You should probably version your fork separately from the official version to avoid confusion.

## Do I have to maintain backwards compatibility with the VICII?

No. It's your fork. You can do whatever you want. You can design a new graphics chip that is completely incompatible with the 6567/6569 chips if you want.  We just ask that the extra mem interface and the registers 00-5f remain consistent between forks. It is just a nice-to-have ask that makes identifying variants convenient but is not in any way mandatory.

## What are some things I can do in my fork?

Here are some possibilities:

1. A math co-processor

   Repurpose some of the unused registers between 0x30 and 0x3c for a math
   co-processor.

2. A display address translator

   Provide a convenient x,y coordinate to memory location & bit function for
   different graphics modes so the CPU doesn't have to make those computations.
   This can make for much faster drawing routines.

3. Extra sprites

   Add a sprite 'bank' register to multiplex in more than 8 sprites.

4. Larger sprites/Wider character cells

   It might be possible to fetch more than one byte inside a half cycle if using 150ns or 120ns RAM.  Some RAM chips have page modes where you can keep the same row address while strobing in successive column addresses.

5. A new video mode/more colors

   Turn one or more of the 'illegal' video modes into a working mode.

6. An 80 column mode

   Try making a 640x200 30fps video mode to get 80 columns. (This would probably need a patched kernel.)

7. Use idle cycles to execute instructions.

8. Another processor

   Add another processor core. It may have to block on read/write until an idle cycle or unused sprite dma cycle is reached.  The addressable range would be limited to 16k and be confined to the same bank as the VIC but this could be interesting.

9. Write to memory from the VIC

   A real VICII chip cannot write to memory since it can't set the WR line LOW.  VICII-Kawari, however, can set WR LOW so this is theoretically possible.

