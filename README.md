# VIC-II Kawari

## What is VIC-II Kawari?
VIC-II Kawari is a hardware replacement for the VIC-II (Video Interface Chip II) found in Commodore 64 home computers. In addition to being compatible with the original VIC-II 6567/6569 chips, some extra features are also available.

This repository contains an open source VIC-II FPGA core written in Verilog.  The bitstream is generated by the ISE 14.7 toolchain from Xilinx and is flashed to compatible hardware. The hardware is available for purchase.

The PCB interfaces with a real C64 address and data bus through the VIC-II socket on the C64 motherboard. The board can replace all the functions of a real VIC-II chip including DRAM refresh, light pen interrupts (real CRT only), PHI2 clock source for the CPU and, of course, video output.

## Forking VIC-II Kawari?

If you intend to fork VIC-II Kawari to add your own features, please read [FORKING.md](FORKING.md)

## What kind of video output options are there?
The core supports these video options:

    DVI (i.e. over an HDMI connector)
    Analog RGB (i.e VGA or RGB for a 1084 monitor)
        R,G,B - .7Vp-p (75 ohm termination)
        H,V   - TTL
    Luma/Chroma (later mixed by the C64's RF modulator for composite video)

    A CSYNC option can be enabled to output composite sync over the H output for some 1084-D monitors.

The core can be configured to support all three or any subset of these options. 

By default, the DVI/RGB signals double the horizontal frequency from ~15.7khz to ~31.4khz (for 2X native height). The horizontal resolution is also doubled to support the 80 column mode.  However, the resolution scaling can be turned off for both width and height if desired.

Video        |Width|Height|Horiz Freq |Vert Freq  |Pixel Clock  |Suitable for
-------------|-----|------|-----------|-----------|-------------|---------------
NTSC         |520  |263   |15.73khz   |59.82hz    |8.181 Mhz    |Composite/RGB
NTSC(Old)    |512  |262   |15.98khz   |60.99hz    |8.181 Mhz    |Composite/RGB
PAL          |504  |312   |15.63khz   |50.125hz   |7.881 Mhz    |Composite/RGB
NTSC         |1040 |263   |15.73khz   |59.82hz    |16.363 Mhz   |RGB
NTSC(Old)    |1024 |262   |15.98khz   |60.99hz    |16.363 Mhz   |RGB
PAL          |1008 |312   |15.63khz   |50.125hz   |15.763 Mhz   |RGB
NTSC         |520  |526   |31.46khz   |59.82hz    |16.363 Mhz   |RGB/DVI
NTSC(Old)    |512  |524   |31.96khz   |60.99hz    |16.363 Mhz   |RGB/DVI
PAL          |504  |624   |31.26khz   |50.125hz   |15.763 Mhz   |RGB/DVI
NTSC         |1040 |526   |31.46khz   |59.82hz    |32.727 Mhz   |RGB/DVI
NTSC(Old)    |1024 |524   |31.96khz   |60.99hz    |32.727 Mhz   |RGB/DVI
PAL          |1008 |624   |31.26khz   |50.125hz   |31.527 Mhz   |RGB/DVI

The DVI/RGB video modes are not standard and may not work with older monitors/TVs or capture cards.  The 15khz modes require a monitor that can handle that horizontal refresh rate.  If the device is configured for 15khz RGB output, DVI will not work.

## How can I find out if my VGA/DVI/HDMI monitor supports the video?
TODO : xrandr or windows equiv to test monitor

## What chip models can this replace?
It can replace the 6567R8(NTSC),6567R56A(NTSC),6569R5(PAL-B),6569R1(PAL-B) models. It can assume the functionality of either video standard with a simple configuration change followed by a cold boot. This means your C64 can be both an NTSC and PAL machine. (PAL-N / PAL-M are not supported but if someone wants to do the work, it can be added.)

## Will this work in C64-C (short board) models?
It will function if plugged into a C64-C 'short' board. The VDD pin is not connected so there is no voltage compatibility issue like with the real 8562/8565 models. Keep in mind that the board will behave as a 6567/6569 even when replacing a 8562/8565.

## Isn't the quality of 6567R56A composite video bad?
The 6567R56A composite signal is known to be worse than the 6567R8. The cycle schedule (and hence timing) is slighly different in the 6567R56A. It generates a composite signal slightly out of range from the expected 15.734khz horizontal frequency for NTSC (it generates 15.980khz instead). Some composite LCD monitors don't like this and even the real chips produced unwanted artifacts on those types of displays. You will get the same unwanted artifacts from a VIC-II Kawari producing composite video when configured as a 6567R56A. CRTs, however, are more forgiving and you may not notice the difference. When using DVI or VGA output, this is of no concern as long as your monitor can handle the frequency (the image will look just as good as any other mode). There may be _some_ NTSC programs that depend on 6567R56A to run properly due to the cycle schedule but I'm not aware of any.

## What about the 6569R3/R4?
There are subtle differences between the PAL revisions mostly to do with luminance levels. I included the 6569R1 as an option since it has 5 luminance levels instead of 8.

## Do I need a functioning clock circuit on my motherboard?
No. The clock input pins (color and dot) are not connected. The board comes with its own clock and can switch between PAL and NTSC timing with a configuration change. (So if your C64 has died due to a malfunctioning clock circuit, this is an option to get your machine back to a working state).

## Do I need to modify my C64 motherboard?
The board will function without any modifications to the motherboard. If you can find a way to get a video cable out of the machine, there is no reason to modify the machine. However, it is much easier if the RF modulator is removed. The hole previously used for the composite jack may then be used for an HDMI or VGA cable. Otherwise, there is no practical way for a video cable to exit the machine unless you drill a hole or fish the cable out the casette or user port space.

NOTE: Strain relief on the cable is VERY important as it exits the machine.  No matter the solution, it is imperative the cable not be allowed to pull on the board while it is in the socket.

## How accurate is it?
To measure accuracy, I use the same suite of programs VICE (The Versatile Commodore Emulator) uses to catch regressions in their releases. Out of a total of 280 VIC-II tests, 280 are passing.

I can't test every program but it supports all the graphics tricks programmers used in their demos/games. It is safe to say it is a faithful reproduction of the original chips.

## Is this emulation?
That's a matter of opinion. Some people consider an FPGA implementation that 'mimics' hardware to be emulation because some behavior is being re-implemented using a high level hardware description language. But it's important to note that the PCB is not 'running' a program like you would on a PC. The PCB is providing a real clock signal to drive the 6510 CPU. It's also generating real CAS/RAS timing signals to refresh DRAM. It is interacting with the same address and data bus that a genuine chip would.

## Will digital video make my C64 look like an emulator?
Yes. The pixel perfect look on an HDMI monitor will resemble an emulator. There is an option that will render ever other line with half brightness giving a raster line effect.  This makes the picture look slightly darker though.  Other than that, there is no effort to make digital video look like a CRT. If you want the look of a CRT, you should chose the VGA or composite options and use a real CRT. Also, the resolution will not match an HDMI monitor's native resolution so there will always be some scaling taking place.

## Will DVI/VGA add delay to the video output?
There is no frame buffer for video output. However, there is a single raster line buffer necessary to double the 15khz horizontal frequency. Although this adds a very small delay, it is a tiny fraction of the frame rate and is imperceivable by a human. For DVI, any additional latency will be from the monitor you use. Most TVs have a 'game mode' that turns off extra processing that can introduce latency and it is highly recommended you use that feature.

## Do light pens work?
Yes. However, light pens will only work using a real CRT with composite. (LCD/DVI/HDMI or even VGA monitors will not work with light pens.)

## This is more expensive. Why not just buy a real one?
If you need a VIC-II to replace a broken one, you should just buy one off eBay. This project is for fun/interest and would certainly cost more than just buying the real thing. However, there are some advantages to using VIC-II Kawari:

* No 'VSP' bug
* Configurable color palette (262144 RGB color space, 32768 HSV color space)
* No need for a working clock circuit
* Can software switch between NTSC and PAL
* Optional NTSC/PAL hardware switch available
* Four chip models supported (6567R56A, 6567R8, 6569R1, 6569R5)
* An 80 column mode and new graphics modes
* An 80 column Novaterm driver
* It's not an almost 40 year old device that may fail at any time

Also, since the core is open source, hobbyests can add their own interesting new features (i.e. a math co-processor, more sprites, more colors, a new graphics mode, a display address translator, etc) See [FORKING.md](FORKING.md) for some a list of possible add-ons.

## What extra features are available?

### A configurable color palette

Each of the Commodore 64's 16 colors can be changed.  For RGB based video (DVI/VGA), an 18-bit color space is available (262144 colors).  For composite (luma/chroma) video, a 15-bit HSV color space is available (32768 colors).  The color palette can be saved and restored on a cold boot.

### An 80 column text mode

A true 16 color 80 column text mode is available. This is NOT a soft-80 mode that uses bitmap graphics but rather a true text mode. Each character cell is a full 8x8 pixels. An 80 colum text screen occupies 4k of kawari video memory space (+4k character definition data). A small program (2k resident at $c800) can enable this for the basic programming environment. The basic text editor operates exactly as the 40 column mode does since the input/output routines are simply copies of the normal kernel routines compiled with new limits. This mode also takes advantage of hardware accelerated block copy/fill features of VIC-II Kawari so scrolling/clearing the text is fast.

There is also a novaterm 9.6 video driver available.

### New graphics modes

In addition to the 80 column text mode, three bitmap modes have been
added for you to experiment with:

    640x200 16 color - Every 8x8 cell can be one of 16 foreground colors or the background color.
    320x200 16 color - Every pixel can be set to one of 16 colors.
    640x200 4 colors - Every pixel can be set to one of 4 colors.

### Software switch between PAL and NTSC

A configuration utility is provided which allows you to change the chip model at any time. Changes to the chip model will be reflected on the next cold boot. This means you can switch your C64 between NTSC and PAL with ease AND without opeing up your machine!

## What are the installation options?

### Composite - No mod

Simply plug VIC-II Kawari into the VIC-II socket.  No modifications are necessary.

### VGA + RF Modulator Removal or Replacement

In this configuration, the RF modulator is removed or replaced with a device that continues to generate the composite signal for the video output port. The hole previously used for RF out is used for a custom VGA cable connected to the header on Kawari.

NOTE: Strain relief is important!

NOTE: You can get away without removing the RF modulator but then you will have the challenge of getting the VGA cable out of a closed machine.  I don't recommend drilling holes but this is an option. Another option is to fish the cable out the user port opening, if you don't plan on using any user port connections.

### DVI + RF Modulator Removal or Replacement

In this configuration, the RF modulator is removed or replaced with a device that continues to generate the composite signal for the video output port. The hole previously used for RF out is used for an HDMI cable connected to the Kawari.

NOTE: Strain relief is important!

NOTE: You can get away without removing the RF modulator but then you will have the challenge of getting the cable out of a closed machine.  I don't recommend drilling holes but this is an option. Another option is to fish the cable out the user port opening, if you don't plan on using any user port connections.

## Limitations

# Cartridges that use DOT clock pin (pin 6)

Any cartridge that uses the DOT clock signal on pin 6 will likely not function with VIC-II Kawari. This is because VIC-II Kawari bypasses the motherboard's clock circuit.  The signal that reaches pin 6 of the cartridge port comes from that circuit. It will therefore be out of sync/phase with the clock that is driving the CPU and data on the bus.  I'm not aware of any specific cartridges that use this pin but if there are any, they would be specialty cartridges (like SuperCPU, REU, etc).  As cartridges that do not function are discovered, they will be added to a list here.

# Mallicious apps

VIC-II Kawari was built to be detected, flashed and re-configured from the C64 main CPU. However, there is nothing stopping a mallicious program from attempting to 'brick' your VIC-II Kawari (i.e. erasing the flash memory) or making it look like your VIC-II Kawari has died (i.e. setting all colors to black or chaning VGA resolution that your monitor doesn't support).  For this reason, there are 3 'lock' bits that can be configured via jumpers.  

See [REGISTERS.md](REGISTERS.md) for a description of the lock bits.

By default, flash operations are disabled. This means in order to allow the flash program to work, you must physically add a jumper to Pin 1. It is recommended you remove it after you've flashed the device.

By default, persistence (extended register changes surviving between reboots) is enabled.  Once you've set your preferred color scheme or other preferences with the config apps, you can place a jumper on Pin 2 to prevent any program changing them without your knowledge.

Access to extensions registers (access to extended features) are enabled. If you want your VIC-II Kawari to function as a normal 6567/6569 and be undetectable to any program (including Kawari config apps) then shorting the extension lock will do that. (NOTE: That includes being able to software switch the video standard. However, a hardware switch will still function.)

