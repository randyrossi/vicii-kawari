# VICII-Kawari

## What is VICII-Kawari?
VICII-Kawari is a hardware replacement for the VIC-II (Video Interface Chip II) found in Commodore 64 home computers.  In addition to being compatible with the original VIC-II 6567/6569 chips, some extra features are also available. It can be considered to be a video upgrade card for your C64.

This project contains:

1. an open source VIC-II FPGA core written in Verilog
2. schematics and PCB design for a replacement board based on the Xilinx Spartan6 FPGA

The PCB interfaces with a real C64 address and data bus through the VIC-II socket on the C64 motherboard. The board can replace all the functions of a real VIC-II chip including DRAM refresh, light pen interrupts (real CRT only), PHI2 clock source for the CPU and, of course, video output.

## Forking VICII-Kawari?

If you intend to fork VICII-Kawari to add your own features, please read [FORKING.md](FORKING.md)

## What kind of video output options are there?
The board has a single DVI-I connector. Using the standard release image, you can connect it to either an HDMI or VGA monitor (with appropriate adapter and cable).

By default, the VGA and HDMI modes double the horizontal frequency from ~15.7khz to ~31.4khz (for 2X native height). The video mode is not standard and may not work with older monitors/TVs or HDMI capture cards.  A 15khz RGB output may be possible for CRTs that support it.

TODO : xrandr or windows equiv to test monitor

## What chip models can this replace?
It can replace the 6567R8(NTSC), 6567R56A(NTSC) and the 6569(PAL-B) models.  It can assume the functionality of either video standard with a simple configuration change followed by a cold boot. This means your C64 can be both an NTSC and PAL machine. (PAL-N / PAL-M are not supported.)

## Will this work in C64-C (short board) models?
It will function if plugged into a C64-C 'short' board. The VDD pin is not connected so there is no voltage compatibility issue like with the real 8562/8565 models.  However, the design is for breadbin models.  It is unlikely you will be able to close the machine as there is not enough room.  It is possible another board design will be produced in the future.

Also, keep in mind that the board will behave as a 6567/6569 even when replacing a 8562/8565. (The differences are minor, though.)

## What about the 6569R1/R3/R5?
There are subtle differences between the different revisions mostly to due with luminance levels. Precicely matching those differences was not a goal of the VICII-Kawari project. The board provides one 6569 option to cover all these models.

## Do I need a functioning clock circuit on my motherboard?
No. The clock input pins (color and dot) are not connected. The board comes with its own clock and can switch between PAL and NTSC timing with a configuration change. (So if your C64 has died due to a malfunctioning clock circuit, this is an option to get your machine back to a working state).

## Do I need to modify my C64 motherboard?
The board will function without any modifications to the motherboard. However, it is recommended the RF modulator be removed. The hole previously used for the composite jack may then be used for an HDMI or VGA cable. Otherwise, there is no practical way for a video cable to exit the machine.  

## How accurate is it?
To measure accuracy, I use the same suite of programs VICE (The Versatile Commodore Emulator) uses to catch regressions in their releases.  Out of a total of 280 VICII tests, 280 are passing.

I can't test every program but it supports all the graphics tricks programmers used in their demos/games. It is safe to say it is a faithful reproduction of the original chips.

## Is this emulation?
This is a matter of opinion. Some people consider FPGA hardware that 'mimicks' real hardware simply another form of emulation.

## Will HDMI make my C64 look like an emulator?
Yes. The pixel perfect look of HDMI output will resemble an emulator.  However, the default display mode applies half brightness to alternating lines, yeilding a raster line effect.  This makes the picture look slightly darker though.  Other than that, there is no effort to make HDMI look like a CRT. If you want the look of a CRT, you should chose the VGA option and use a real CRT (and turn off rasterline effect). Also, the resolution will not match an HDMI monitor's native resolution so there will always be some scaling taking place.

## Will HDMI/VGA add delay to the video output?
There is no frame buffer for video output. However, there is a single raster line buffer necessary to double the 15khz horizontal frequency. Although this adds a very small delay, it is a tiny fraction of the frame rate and is imperceivable by a human. For HDMI, any additional latency will be from the monitor you use. Most TVs have a 'game mode' that turns off extra processing that can introduce latency and it is highly recommended you use that feature.

## Do light pens work?
Yes. However, light pens will only work using an analog mode (VGA) and only on a real CRT. (LCD or HDMI monitors will not work with light pens.)

## This is more expensive. Why not just buy a real one?
If you need a VIC-II to replace a broken one, you should just buy one off eBay. This project is for fun/interest and would certainly cost more than just buying the real thing. However, there are some advantages to using VICII-Kawari:

* No 'VSP' bug
* Configurable color palette (4096 color space, two 16 color palettes available)
* No need for a working clock circuit
* Can software switch between NTSC and PAL
* An 80 column mode and new graphics modes
* It's not an almost 40 year old device that may fail at any time

Also, since the core is open source, hobbyests can add their own interesting new features (i.e. a math co-processor, more sprites, more colors, a new graphics mode, a display address translator, etc) See [FORKING.md](FORKING.md) for some a list of possible add-ons.

## What extra features are available?

### A configurable color palette

Each of the Commodore 64's 16 colors can be changed with RGB values inside a 12 bit color space (4096 colors).  There are two 16 color palettes available. Palette 1 or 2 is selected by a register.  (This feature is intended to be used for programming, not for user's video preferences. Changes to the color palette are not persisted between cold reboots.)

### An 80 column text mode

A true 16 color 80 column text mode is available. This is NOT a soft-80 mode that uses bitmap graphics but rather a true text mode. Each character cell is a full 8x8 pixels. An 80 colum text screen occupies 4k of kawari video memory space (+4k character definition data). A small program (2k resident at $c800) can enable this for the basic programming environment.  The basic text editor operates exactly as the 40 column mode does since the input/output routines are simply copies of the normal kernel routines compiled with new limits.

### New graphics modes

In addition to the 80 column text mode, three bitmap modes have been
added for you to experiment with:

    640x200 16 color - Every 8x8 cell can be one of 16 foreground colors or the backgroudn color.
    320x200 16 color - Every pixel can be set to one of 16 colors.
    640x200 4 colors - Every pixel can be set to one of 4 colors.

### Software switch between PAL and NTSC

A configuration utility is provided which allows you to change the chip model at any time. Changes to the chip model will be reflected on the next cold boot. This means you can switch your C64 between NTSC and PAL with ease AND without opeing up your machine!

## What are the installation options?

### VGA + RF Modulator Removal

In this configuration, the RF modulator is removed. The hole previously used for RF out is used for a VGA cable connected to the DVI port. No video signals will be present at the C64's video port.

NOTE: You can get away without removing the RF modulator but then you will have the challenge of getting the VGA cable out of a closed machine.  I don't recommend drilling holes but this is an option. Another option is to fish the cable out the user port opening, if you don't plan on using any user port connections.

### HDMI + RF Modulator Removal

In this configuration, the RF modulator is removed. The hole previously used for RF out is used for a HDMI cable connected to the DVI port. No video signals will be present at the C64's video port.

NOTE: You can get away without removing the RF modulator but then you will have the challenge of getting the HDMI cable out of a closed machine.  I don't recommend drilling holes but this is an option. Another option is to fish the cable out the user port opening, if you don't plan on using any user port connections.

### Is there a mod-less option?

A mod-less composite option is thoeretically possible but has not yet been attempted.  In this configuration, a composite encoder board is plugged into the video output port of the VICII-Kawari.  This board would generate the required LUMA/CHROMA signals to be fed back into the motherboard.  No modifications to the machine would be necessary in this configuration.  Video out would be taken from the normal output jack and the RF modulator would still be necessary.

As stated above, this option is theoretically possible but no such adapter board has been created.  There are some technical challenges to overcome.  The voltage levels for LUMA/CHROMA signals going back into the motherboard would have to match what the RF modulator circuits are expecting. Also, it's not clear whether NTSC / PAL signals would be compatible with one or the other type of RF modulator.

