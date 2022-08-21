<b><p align=center> STATUS Aug 20, 2022: I've put in an order for 200 'Mini' boards. I was also able to get both the large and mini boards working with the MK2 Reloaded. I also fixed an issue with SaRuMan on 250407 (and possibly others). Firmware update pending. I may set up an online store front instead of selling on eBay.</p></b>

# VIC-II Kawari

## What is VIC-II Kawari?
VIC-II Kawari is a hardware replacement for the VIC-II (Video Interface Chip II) found in Commodore 64 home computers. In addition to being compatible with the original VIC-II 6567/6569 chips, some extra features are also available. See [REGISTERS.md](doc/REGISTERS.md)

This repository contains an open source VIC-II FPGA core written in Verilog. Three PCB designs/configurations are possible ranging from (approximately) $30 BOM cost to $80 BOM cost.

The PCB interfaces with a real C64 address and data bus through the VIC-II socket on the C64 motherboard. The board can replace all the functions of a real VIC-II chip including DRAM refresh, light pen interrupts (real CRT only), PHI2 clock source for the CPU and, of course, video output.

## Forking VIC-II Kawari?

If you intend to fork VIC-II Kawari to add your own features, please read [FORKING.md](doc/FORKING.md)

## What kind of video output options are there?

Please note that the video options available depends on the board design and configuration:

Board Design | DVI | Analog RGB | Luma/Chroma | Extensions/Switching
-------------|-----|------------|-------------|---------------------
Kawari-Large | Yes | Yes        | Yes         | Yes
Kawari-Mini  | No  | No         | Yes         | Yes
Kawari-POV   | No  | No         | Yes         | No

'POV' Stands for Plain Old VIC and is meant to be nothing more than a VIC-II replacement (no extra features)

For a chart breaking down all features available or missing for a particular board design, please see [MODELS.md](doc/MODELS.md)

Video Option | Connector  | Notes
-------------|------------|-------
DVI          | Micro HDMI |User must fish cable out of machine and provide strain relief
Analog RGB   | Header     |User must build custom RGB connector, fish cable out of machine and provide strain relief, RGB:.7Vp-p (75 ohm termination) HV:TTL
Luma/Chroma  | A/V Jack   |Regular S/LUM output at rear of computer (composite or s-video)

The core is flexible and can be configured to support all three or any subset of these video options provided the hardware can support it.

By default, the DVI/RGB signals double the horizontal frequency from ~15.7khz to ~31.4khz (for 2X native height). The horizontal resolution is also doubled to support the 80 column mode.  However, the resolution scaling can be turned off for both width and height.  (NOTE: Turning off horizontal scaling will prevent hires modes from working properly.)

Video        |Width|Height|Horiz Freq |Vert Freq  |Pixel Clock  |Suitable for
-------------|-----|------|-----------|-----------|-------------|---------------
NTSC         |520  |263   |15.73khz   |59.82hz    |8.181 Mhz    |RGB
NTSC(Old)    |512  |262   |15.98khz   |60.99hz    |8.181 Mhz    |RGB
PAL-B        |504  |312   |15.63khz   |50.125hz   |7.881 Mhz    |RGB
NTSC         |1040 |263   |15.73khz   |59.82hz    |16.363 Mhz   |RGB
NTSC(Old)    |1024 |262   |15.98khz   |60.99hz    |16.363 Mhz   |RGB
PAL-B        |1008 |312   |15.63khz   |50.125hz   |15.763 Mhz   |RGB
NTSC         |520  |526   |31.46khz   |59.82hz    |16.363 Mhz   |RGB/DVI
NTSC(Old)    |512  |524   |31.96khz   |60.99hz    |16.363 Mhz   |RGB/DVI
PAL-B        |504  |624   |31.26khz   |50.125hz   |15.763 Mhz   |RGB/DVI
NTSC         |1040 |526   |31.46khz   |59.82hz    |32.727 Mhz   |RGB/DVI
NTSC(Old)    |1024 |524   |31.96khz   |60.99hz    |32.727 Mhz   |RGB/DVI
PAL-B        |1008 |624   |31.26khz   |50.125hz   |31.527 Mhz   |RGB/DVI

### More video stuff

The DVI video modes are not standard and may not work with older monitors/TVs or capture cards.  The 15khz modes require a monitor that can handle that horizontal refresh rate.  If the device is configured for 15khz, DVI will not work.

The PCB has an unpopulated 10 pin analog header (1 +5V, 6 signal, 3 GND) that can wired to a monitor with a custom built cable.

    +5V CLK GND RED GRN
    GND VSY HSY BLU GND

For 1080/1084-D monitors, a CSYNC option can be enabled to output composite sync over the horizontal sync pin.  1084-S monitors use the default separated HSYNC and VSYNC signals.

NOTE: The CLK pin (dot clock) is disabled as it is not necessary for analog connections.  If you need it, it can be enabled with a firmware update.

#### FEMALE 6-PIN PORT AS VIEWED FROM REAR OF 1084-S

       _______       Pin#      Signal
      /   3   \      Pin 1     G  Green
     / 2     4 \     Pin 2     HSYNC Horizontal Sync
    |     6     |    Pin 3     GND Ground
     \ 1  _  5 /     Pin 4     R  Red
      \__/ \__/      Pin 5     B  Blue
                     Pin 6     VSYNC Vertical Sync

#### MALE 9-PIN PORT AS VIEWED FROM REAR OF 1080/1084-D (Analog RGB Mode)

                     Pin  Name     Signal
    _____________     1   GND      Ground
    \ 1 2 3 4 5 /     2   GND      Ground
     \_6_7_8_9_/      3   R        Red
                      4   G        Green
                      5   B        Blue
                      6   I        not used
                      7   CSYNC    Composite Sync (Enable CSYNC option in config)
                      8   HSYNC    not used
                      9   VSYNC    not used

    The x2 native width video modes work on 1080/1084 monitors (requred for 80 column/hires modes).

A SCART adapter should be possible but has not been built/tested.

## How can I find out if my VGA/DVI/HDMI monitor supports the video?
You can try these xrandr commands on Linux to test out a 50hz mode very similar to the one Kawari outputs. Replace DP-1 with your active HDMI or DP device:

    xrandr --delmode DP-1 my50hzmode
    xrandr --newmode my50hzmode 35.52 966 976 1072 1136 604 606 612 624 -hsync -vsync
    xrandr --addmode DP-1 my50hzmode
    xrandr --output DP-1 --mode my50hzmode

## What chip models can this replace?
The 'Large' and 'Mini' models can replace the 6567R8(NTSC),6567R56A(NTSC),6569R3(PAL-B),6569R1(PAL-B) models. They can assume the functionality of either video standard with a simple configuration change followed by a cold boot. This means your C64 can be both an NTSC and PAL machine. (PAL-N / PAL-M are not supported but it can be added with some hardware modifications.)  The 'POV' model cannot behave as 'old' chip models (R56A/R1) and are fixed to either a 6567R8 or 6569R3.

## What motherboard revisions will this fit?
The 'Mini/POV' boards will fit into revisions 250407, 250425, 326298 & KU-14194HB. For 250425 boards, the RF sheild must be removed. For 250407, 326298 and KU-14194HB, the 'top' cover of the RF sheild compartment must be removed.

The 'large" board will fit into revisions 250407, 250425, 326298 & KU-1419HB provided an extra socket is included to give the PCB enough height to clear some of the clock circuit components.  However, if present, the RF sheild surrounding the video circuitry will prevent an HDMI cable from being plugged in even with an extra socket.  For better HDMI port access, the large board is recommended for boards that do not have an RF sheild surrounding the video circuit.  Also, it is better if the RF modulator is unpopulated or replaced with a RF modulator bypass board.  This leaves room for a cable to be plugged in and exit the machine through unused holes at the back.  Strain relief is up to the user.

## Will this work in C64-C (short board) models?
Although the board will (mostly) function if plugged into a C64-C 'short' board (i.e. 250469), the current versions of VIC-II Kawari are not recommended for these motherboards.

1. It is difficult to close the machine. The 'Mini' PCB sits too high off the motherboard which presses up on the sheilding (required to be installed due to keyboard support brackets being attached).  The large also requires an extra socket to clear some motherboard components and causes the same issue with the sheild. If you are willing to replace the sheild with 3D printed keyboard support brackets (or other solutions), you may be able to get it to fit into a closed machine. However, this has not been tested.

2. The 8562/8565 CAS/RAS timing is slightly different than the older generation 6567/6569 chips. You can try flashing an alternate firmware that adjusts the timing. However, there are still some issues that can cause some games/demos to fail. For this reason, I am not recommending VIC-II Kawari for C64-C short boards.

NOTE: The VDD pin is not connected so there is no voltage compatibility issue like with the real 8562/8565 models. It won't damage the Kawari to plug it into a C64-C 'short' board. You may run into the issues described above, however.

## Isn't the quality of 6567R56A composite video bad?
The 6567R56A composite signal is known to be worse than the 6567R8. The cycle schedule (and hence timing) is slighly different in the 6567R56A. It generates a signal slightly out of range from the expected 15.734khz horizontal frequency for NTSC (it generates 15.980khz instead). Some composite LCD monitors don't like this and even the real chips produced unwanted artifacts on those types of displays. You will get the same unwanted artifacts from a VIC-II Kawari producing composite video when configured as a 6567R56A. Most CRTs, however, are more forgiving and you may not notice the difference. Some TVs still show a bad picture. When using DVI or RGB output, this is of no concern as long as your monitor can handle the frequency (the image will look just as good as any other mode). There may be _some_ NTSC programs that depend on 6567R56A to run properly due to the cycle schedule but I'm not aware of any.  The default config defines only 5 luminance levels for the 6567R56A.

## What about the 6569R4/R5?
There are subtle differences between the PAL-B revisions mostly to do with luminance levels. I included the 6569R1 as an option.  Keep in mind the default luma config has only 5 luminance levels instead of 8 and also has a light pen irq trigger bug. (There's nothing stopping you from defining 8 lumanance levels for the 6569R1 though).

## What about the 6572?
It is, in theory, possible to re-purpose one of the video standards to be a 6572 (South America PAL-N). It would require a firmware change and the board would have to be configured to use the motherboard's clock (or one of the oscillators changed to match PAL-N frequency).  Either NTSC or PAL-B could be replaced with PAL-N. As far as I can tell, the only reason to do this would be to get real Argentinian CRTs/TVs to display a composite signal correctly while being (mostly) compatible with NTSC software. (This is a lower priority project but if someone else wants to take on the challenge, it could appear as a fork.)

## Do I need a functioning clock circuit on my motherboard?
This depends on how the VIC-II Kawari PCB has been populated and configured. The 'Large' and 'Mini' boards come with on-board oscillators for both NTSC and PAL-B standards. In that case, the motherboard's clock circuit can be bypassed. However, the board can be configured to use the motherboard's clock for the machine's 'native' standard via jumper config. In that case, one of the two video standards can be driven by the motherboard's clock.  Please see [Limitations/Caveats](#limitationscaveats) below regarding pin 6 of the cartridge port.  The 'POV' model must use the motherboard's clock and cannot switch video standards. Refer to the table below for C.SRC jumper settings.

## How do the C.SRC jumpers work?

For 'Large' and 'Mini' boards, the C.SRC jumpers let you select the clock source for the two video standards the board supports. By default, both video standards are driven by on-board oscillators (if the board has been populated with them).  However, you have the option of using the machine's 'native' clock source for one of the video standards.  This is an option in case some specialty cartridges require the use of Pin 6 on the cartridge port. See [Limitations/Caveats](#limitationscaveats)

Here is a table describing the valid jumper configurations:

PAL-B Jumper | NTSC Jumper | Description
:--------:|:--------:|------------
<span style="font-family:fixed;line-height:1em;">█<br><br>█<br>│<br>█</span>|<span style="font-family:courier;line-height:1em;">█<br><br>█<br>│<br>█</span>|Uses on-board oscillators for both video standards.  Some specialty cartridges using Pin 6 of cartridge port may not work.

PAL-B Jumper | NTSC Jumper | Description
:--------:|:--------:|------------
<span style="font-family:fixed;line-height:1em;">█<br>│<br>█<br><br>█</span>|<span style="font-family:courier;line-height:1em;">█<br><br>█<br>│<br>█</span>|Uses on-board oscillator for NTSC, motherboard clock for PAL-B.  Board will only work in PAL-B mode on a PAL-B machine. Some specialty cartridges using Pin 6 of cartridge port may not work in NTSC mode.

PAL-B Jumper | NTSC Jumper | Description
:--------:|:--------:|------------
<span style="font-family:fixed;line-height:1em;">█<br><br>█<br>│<br>█</span>|<span style="font-family:courier;line-height:1em;">█<br>│<br>█<br><br>█</span>|Uses on-board oscillator for PAL-B, motherboard clock for NTSC. Board will only work in NTSC mode on a NTSC machine.  Some speciality cartridges using Pin 6 of cartridge port may not work in PAL-B mode.


## Do I need to modify my C64 motherboard?
The board will function without any modifications to the motherboard. If you can find a way to get a video cable out of the machine, there is no reason to modify the machine. However, it is much easier if the RF modulator is removed. The hole previously used for the composite jack may then be used for an HDMI or VGA cable. Otherwise, there is no practical way for a video cable to exit the machine unless you drill a hole or fish the cable out the casette or user port space.

IMPORTANT! Strain relief on the cable is VERY important as it exits the machine.  No matter the solution, it is imperative the cable not be allowed to pull on the board while it is seated in the motherboard socket.

## How accurate is it?
To measure accuracy, I use the same suite of programs VICE (The Versatile Commodore Emulator) uses to catch regressions in their releases. Out of a total of 280 VIC-II tests, 280 are passing (at least by visual comparison).

I can't test every program but it supports the graphics tricks programmers used in their demos/games. Refer to the Hardware/Software compatibility matrix below. Although perhaps not perfect, it is safe to say it is a faithful reproduction of the original chips.

## Is this emulation?
That's a matter of opinion. Some people consider an FPGA implementation that 'mimics' hardware to be emulation because some behavior is being re-implemented using a high level hardware description language. But it's important to note that the PCB is not 'running' a program like you would on a PC. The PCB is providing a real clock signal to drive the 6510 CPU. It's also generating real CAS/RAS timing signals to refresh DRAM. It is interacting with the same address and data bus that a genuine chip would.

## Will digital video make my C64 look like an emulator?
Yes. The pixel perfect look on an HDMI monitor will resemble an emulator. There is an option that will render ever other line with half brightness giving a raster line effect.  This makes the picture look slightly darker though.  Other than that, there is no effort to make digital video look like a CRT. If you want the look of a CRT, you should chose the VGA or composite options and use a real CRT. Also, the resolution will not match an HDMI monitor's native resolution so there will always be some scaling taking place.

## Will DVI/VGA add delay to the video output?
There is no frame buffer for video output. However, there is a single raster line buffer necessary to double the 15khz horizontal frequency. Although this adds a very small delay, it is a tiny fraction of the frame rate and is imperceivable by a human. For DVI, any additional latency will be from the monitor you use. Most TVs have a 'game mode' that turns off extra processing that can introduce latency and it is highly recommended you use that feature.

## My DVI/HDMI monitor stretches the picture. Can that be changed?
The video signals are output at native resolution (or 2x) and since there is no frame buffer, the aspect ratio of the image cannot be adjusted. It will be up to your monitor/TV to support 4:3 aspect ratio to display something that doesn't look 'stretched'.  I have no plans on making the DVI/HDMI image look like an analog display.

## Do light pens work?
Yes. However, light pens will only work using a real CRT with composite. (LCD/DVI/HDMI or even VGA monitors will not work with light pens.)

## This is more expensive. Why not just buy a real one?
If you need a VIC-II to replace a broken one, you should just buy one off eBay. This project is for fun/interest and would certainly cost more than just buying the real thing. However, there are some advantages to using VIC-II Kawari ('Large/Mini' models):

* No 'VSP' bug
* Configurable color palette (262144 RGB color space, 262144 HSV color space)
* No need for a working clock circuit
* Can software switch between NTSC and PAL-B
* Optional NTSC/PAL-B hardware switch
* Four chip models supported (6567R56A, 6567R8, 6569R1, 6569R3)
* An 80 column mode and new graphics modes
* An 80 column Novaterm driver
* Some fun 'extras' to play around with
* It's not an almost 40 year old device that may fail at any time

Also, since the core is open source, hobbyests can add their own interesting new features (i.e. a math co-processor, more sprites, more colors, a new graphics mode, a display address translator, etc) See [FORKING.md](doc/FORKING.md) for some a list of possible add-ons.

## What extra features are available ('Large/Mini' models)?

### A configurable color palette

Each of the Commodore 64's 16 colors can be changed for preference. For RGB based video (DVI/VGA), an 18-bit color space is available (262144 colors). For composite (luma/chroma) video, a 18-bit HSV color space is available (262144 colors). The color palette can be saved and restored on a cold boot and is configurable for each chip separately.

### An 80 column text mode

A true 16 color 80 column text mode is available. This is NOT a soft-80 mode that uses bitmap graphics but rather a true text mode. Each character cell is a full 8x8 pixels. An 80 colum text screen occupies 4k of kawari video memory space (+4k character definition data). A small program (2k resident at $c800) can enable this for the basic programming environment. The basic text editor operates exactly as the 40 column mode does since the input/output routines are simply copies of the normal kernel routines compiled with new limits. This mode also takes advantage of hardware accelerated block copy/fill features of VIC-II Kawari so scrolling/clearing the text is fast.

NOTE: 40 column BASIC programs will not necessarily run without modification in the 80 column mode. If the program uses print statements exclusively, then there's a good chance it will work.  If it uses POKEs to screen memory, it will have to be modified.

NOTE: The 80 column display was not intended for TVs or low resolution monitors. The mode will function using a composite signal but the bandwidth is too low and you will not get a sharp display.  You may get a more usable image using a custom s-video cable (and possibly an upscaler).

### Novaterm 9.6c 80 column driver

A Novaterm 9.6c 80 column video driver is available.  Use this driver with a user port or cartridge modem and relive the 80's BBS experience in 80 columns on your C64!

### New graphics modes

In addition to the 80 column text mode, three bitmap modes have been added for you to experiment with:

    640x200 16 color - Every 8x8 cell can be one of 16 foreground colors or the background color.
    320x200 16 color - Every pixel can be set to one of 16 colors.
    640x200 4 colors - Every pixel can be set to one of 4 colors.
    160x200 16 colors - Every pixel can be set to one of 16 colors.

#### Notes about sprites in hires-modes

Low-res sprites will show up on the hi-res modes. However, they behave according to low-res mode rules. That means their x-positions are still low resolution. Background collisions will trigger based on hi-res screen data, but cannot detect collisions at the 'half' pixel resolution. Sprite to sprite collisions should work as expected. This was a compromise chosen between adding new hires sprite support (taking up a lot of FPGA space) and having no sprites at all.  For the 320x200 and 640x200 bitmap modes, a pixel is considered to be background if it matches the background color register value.  Otherwise, it is foreground.

### More RAM

There is an additional 64K of video ram. This is RAM that the video 'chip' can access directly for the new hires modes.  It can also be used to store data and there is a DMA transfer function that can copy between DRAM and VRAM quickly without using CPU resources.

### Hardware DIV and MUL registers

Hardware divide and multiply registers were added to avoid costly loops. Some programs can be modified to take advantage of these registers.

### Blitter/Copy/Fill

A blitter is availble to copy rectangular regions of memory quickly without using the CPU.  There are also block copy and fill routines that can move or fill video ram. These features are useful for the new hi-res modes.

### Software switch between PAL-B and NTSC

A configuration utility is provided which allows you to change the chip model at any time. Changes to the chip model will be reflected on the next cold boot. This means you can switch your C64 between NTSC and PAL-B with ease AND without opening up your machine!

The full featured config utility takes longer to load, so a smaller quick switch program dedicated to changing the chip is also included.

### Hardware switch between PAL-B and NTSC

The 'switch' header on the PCB will toggle the chip model between the saved standard (switch open) and the opposite standard (switch closed). Please note that the 'older' revisions and 'newer' revisions will switch with each other.

What's Saved  | Swith OPEN   | Switch CLOSED
--------------|--------------|--------------
6567R8 NTSC   | 6567R8 NTSC  | 6569R5 PAL-B
6567R56A NTSC | 656756A NTSC | 6569R1 PAL-B
6569R5 PAL-B  | 6569R5 PAL-B | 6567R8 NTSC
6569R1 PAL-B  | 6569R1 PAL-B | 6567R56A NTSC

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

## Config RESET

You can reset the board by temporarily shorting the jumper pads labeled 'Reset' while the device is powered on. The background and border color will turn white to let you know a reset has been detected. Then cold boot. This will prevent the device from reading any persisted settings.  The default palette will be used for all models.  After a config reset, the next time you run any configuration utility, it will prompt you to initialize the device again.

## Can you add feature X and option Y and enhancement Z?

Not really. That's up to you. That's why the project is open source.  Consider my 'MAIN' variant one possibility of what you can do with the device.  However, since my features take up practically all the fabric, you would most likely have to disable some of my 'extras' in favor of yours.

## Hardware Compatibility Matrix

Hardware                    | Status
----------------------------|----------------------------------
Kung Fu Flash Cartridge     | Working as of v1.5 on all long board motherboard revisions I've tested.
SuperCPU                    | Works as long as the motherboard clock is used (jumper setting). Will not work with on-board oscillators.
MK2 Reloaded                | Have firmware update that will work. Check back later for update.
The Final Cartridge         | No issues discovered so far.
Ultimate 1541               | No issues discovered so far.
Pi1541                      | Must turn off GraphIEC feature or else some demos will fail (same with real VIC-II's)
Link232 Wifi Cartridge      | Works but requires motherboard clock jumper setting. Will not work with on-board oscillators.
Turbo Chameleon             | Reported not working
SaRuMan DRAM Replacement    | Can be made to work with a CAS/RAM timing change. Testing on a 250407 board is underway (Aug 6, 2022). Check back later for update.

## Software Compatibility Matrix

Software                | Status 
------------------------|----------
errata (emulamer)       | End screen should slow reveal but quick revelals instead. Cause unknown.
Uncensored (booze)      | Does not advance on disk 2 swap on my 326298 long board. Works on others. But loading directly from disk 2 does work and the rest of the demo plays.
Edge of Disgrace        | Some garbage at the bottom of first face pic on 326298 & 250245. Rest of demo plays fine. Problem does not happen on 250407.

## Other Limitations/Caveats

### Soft Reset + HiRes Modes / Color Registers

Please note that if you change color registers or enable hi-res modes, Kawari will not revert back to the default palette or lo-res modes with a soft reset (or even RUN/STOP restore). If you want the Kawari 'Large' model to detect soft resets, you can connect the through hole pad labeled RST in the upper left corner of the board to the 6510's RESET pin (or any other RESET location) using a jumper wire and grabber.  The 'Mini' and 'POV' models cannot detect resets.

### Cartridges that use DOT clock pin (pin 6)

A cartridge that uses the DOT clock signal on pin 6 may not work when the clock source is set to the on-board oscillator. The signal that reaches pin 6 of the cartridge port comes from the motherboard clock circuit and will likely be out of phase/sync with the clock generated by the on-board oscillator. In this case, you can configure your Kawari to use the motherboard's 'native' clock instead of the on-board oscillator. Note, however, that only the machine's 'native' video standard will work with such a cartridge. Since the vast majority of cartridges do not use pin 6, this should not be a problem for most users. A list of cartridges that are known to have problems may appear here in the future.

### Pi1541 GraphIEC Feature

The Pi1541 has a feature that displays the IEC bus information to its display. This can interfere with tight timing requirements on some demo fast loaders (even on a genuine VIC-II chip) and can lead to corrupted data loaded into memory. If you are experiencing random crashes on demos like 'Uncensored', 'Edge of Disgrace' or similar demos, this is likely the cause. It is recommended you turn this feature off by adding 'GraphIEC = 0' to your options.txt. (I also turn off the buzzer option).

## Function Lock Jumpers

VIC-II Kawari was built to be detected, flashed and re-configured from the C64 main CPU. To prevent a program from (intentionally or accidentally) 'bricking' your VIC-II Kawari, some functions can be locked from programmatic access.

See [REGISTERS.md](doc/REGISTERS.md) for a description of the lock jumpers.

By default, flash operations are DISABLED. This means you must physically remove the jumper on Pin 1 to allow the flash utility to work.  (It is recommended you put the jumper back after you've flashed the device.)

Also by default, persistence (extended register changes persisting between reboots) is ENABLED. Once you've set your preferred color scheme or other preferences with the config apps, you can remove the jumper on Pin 2 to prevent any program changing them without your knowledge/permission. Programs will still be able to change colors. But they won't be able to save them.

Access to extension registers (extended features) are ENABLED by default. If you want your VIC-II Kawari to function as a regular 6567/6569 and be undetectable to any program (including Kawari config apps) then removing the extension lock jumper on Pin 2 will do that. (NOTE: That includes being able to software switch the video standard. However, a hardware switch will still work.)

Without the lock jumpers, here are some ways a misbehaving program can make it look like your VIC-II Kawari has died:

1. erase the flash memory making the device un-bootable (must be restored via JTAG/SPI programmer)
2. change all colors to black and save them, making it look like a black screen fault (restored by shorting CFG jumper pad)
3. change the hires modes to a resolution incompatible with your monitor, again making it look like a black screen fault (restored by shorting CFG jumper pad)

