# VICII-Kawari

## What is VICII-Kawari?
VICII-Kawari is a hardware replacement for the VIC-II (Video Interface Chip II) found in Commodore 64 home computers.

This project contains:

1) an open source VIC-II FPGA core written in Verilog
2) schematics and PCB design for a Xilinx Spartan6 replacement board

The PCB interfaces with a real C64 address and data bus through the VIC-II socket on the C64 motherboard. The board can replace all the functions of a real VIC-II chip including DRAM refresh, light pen interrupts (real CRT only), PHI2 clock source for the CPU and, of course, video output.

## What kind of video output options are there?
There are three video output options:

* Composite
* VGA
* HDMI

NOTE: The VGA and HDMI modes double the horizontal frequency from ~15.7khz to ~31.4khz and are not standard so they may not work on older monitors/TVs or capture cards.  A native 15khz frequency RGB output may also possible for CRTs that support it.

## What chip models can this replace?
It can replace the 6567/8562 (NTSC) models and the 6569/8565 (PAL-B) models. It behaves as a 6567R8 or 6569R9 (even when replacing a 8562 or 8565).  The VDD pin is not connected, so there is no voltage compatibility issue between 'breadbin' and 'short' boards like with the real chips.

Unlike the real chips, however, it can assume the functionality of either NTSC or PAL-B models with a simple configuration change followed by a machine reset. This means your C64 can be both an NTSC and PAL machine.  PAL-N / PAL-M composite out is not supported.  

## Can it be a 6567R56A?
Yes, the 6567R56A is supported.  However, for composite output, be aware that the cycle schedule (and hence timing) is slighly different in the 6567R56A. It generates a composite signal slightly out of range from the expected 15.734khz horizontal frequency for NTSC (15.980khz). Some composite LCD monitors don't like this and the (real) chips produced unwanted artifacts on those types of displays. You will get the same unwanted artifacts from a VICII-Kawari producing composite video when configured as a 6567R56A.  CRTs, however, are more forgiving and you probably wouldn't notice the difference. When using HDMI or VGA output, this is of no consequence. There may be _some_ NTSC programs that depend on 6567R56A to run properly but I'm not awaere of any.

## What about the 6569R1/R3/R5?
There are subtle differences between the different revisions mostly to due with luminance values. Since the palette is configurable (with at least 3 bits of precision), it's not worth adding separate configurations for these revisions.

## Do I need a functioning clock circuit on my motherboard?
No. The clock input pins (color and dot) are not connected. The board comes with its own clock and can switch between PAL and NTSC timing with a configuration change. (So if your C64 has died due to a malfunctioning clock circuit, this is an option to get your machine back to a working state).

## Do I need to modify my board?
It depends on what video output you chose. If you use the composite encoder option, no modifications to the motherboard are required.  However, if you plan on using VGA or HDMI output, it is recommended the RF modulator be removed. The hole previously used for the composite jack may then be used for an HDMI or VGA cable. Otherwise, there is no practical way for a video cable to exit the machine.

## How accurate is it?
I'm going to say 99%. I can't test every program but it supports the graphics tricks programmers used in their demos/games.  So far the results have been excellent but more testing is needed.  Also, it is possible some glitch in the real hardware could be discovered in the future that would require an update to the logic in the core.

## Will HDMI make my C64 look like an emulator?
Yes. The pixel perfect look of HDMI output will resemble an emulator. This may not be desirable by some. There is no attempt to add any video processing to make HDMI look like a CRT (scanlines, curve, etc.)  If you want the look of a CRT, you should chose the Composite/VGA options and use a real CRT.  Also, the resolution will not match an HDMI monitor's native resolution so there will always be some scaling taking place.

## Will HDMI/VGA add delay to the video output?
There is no frame buffer for video output. However, there is a single raster line buffer necessary to double the 15khz horizontal frequency. Although this adds a very small delay, it is a tiny fraction of the frame rate and is imperceivable by a human. For HDMI, any additional latency will be from the monitor you use. Most TVs have a 'game mode' that turns off extra processing that can introduce latency.

## Do light pens work?
Yes, but only if you use one of the analog modes (Composite/VGA) on a real CRT. (LCD or HDMI monitors will not work with light pens.)

## Why not just buy a real one?
If you need a VIC-II to replace a broken one, you should just buy one off eBay. This project is for fun/interest and would certainly cost more than just buying the real thing.  However, there are some advantages to using VICII-Kawari:

* No 'VSP' bug
* Configurable palette
* No need for a working clock circuit
* Can software switch between NTSC and PAL
* It's not a near 40 year old device that may fail at any time

Also, since the core is open source, hobbyests can add their own interesting new features (i.e. a math co-processor, more sprites, more colors, a new graphics mode, another 6510 processor, etc)

## What are the installation options?

### Mod-less Composite

In this configuration, a composite encoder board is plugged into the video output port of the VICII-Kawari.  This feeds LUMA and CHROMA signals back into the motherboard.  No modifications to the machine are necessary in this configuration.  Video out is taken from the normal output jack and the RF modulator is still necessary.

### Simple mod Composite

In this configuration, the same composite encoder is plugged into the video output port.  The RF output jack is disconnected from the RF modulator.  A wire carrying the composite signal from the composite encoder board is then soldered to what used to be the RF output jack.  In this configuration, no video signals be present at the C64's video port.

### VGA + RF Modulator Removal

In this configuration, the RF modulator is removed.  A VGA adapter board is plugged into the VICII-Kawari's video output port.  The hole previously used for RF out is used for a VGA cable connected to the VGA board.  No video signals will be present at the C64's video port.

### HDMI + RF Modulator Removal

In this configuration, the RF modulator is removed.  An HDMI adapter board is plugged into the VICII-Kawari's video output port.  The hole previously used for RF out is used for a HDMI cable connected to the HDMI board.  No video signals will be present at the C64's video port.


