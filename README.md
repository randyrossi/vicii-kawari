# Commodore VIC-IIe Replacement Project

## What is this?
This is a replacement project for the VIC-IIe (Video Interface Chip II) found in Commodore 64 home computers.

This project contains:

1) an open source VIC-IIe FPGA core written in Verilog
2) schematics and PCB design(s) for a Xilinx Spartan6 based board
3) schematics and PCB design(s) for an optional luma/chroma video generator

The PCB interfaces with a real C64 address and data bus through the VIC-IIe socket on the C64 motherboard. The board can replace all the functions of a real VIC-IIe chip including DRAM refresh, light pen interrupts (real CRT only), PHI2 clock source for the CPU and, of course, video output.

## What kind of video output options are there?
There are three video output options:

    1) composite - requires a custom composite adapter based on the Sony CXA1645P composite encoder IC (separate luma/chroma also available for s-video)
    2) VGA - requires a GERT VGA666 adapter board
    3) HDMI - requires an ICEBreaker Pmod Digital Video Interface adapter

NOTE: The VGA and HDMI modes are not standard so they may not work on older monitors/TVs or capture cards.

## What chip models can this replace?
It can replace the 6567 (NTSC/All revisions) and the 6569 (PAL/All revisions). The FPGA core functions as either a 6567R8 or 6569R9. Unlike the original chips, however, it can assume the functionality of either NTSC or PAL models with a simple configuration change followed by a machine reset. This means your C64 can be both an NTSC and PAL machine.

## Can this replace the 8562/8565 found in the 'newer' Commodore 64 short boards?
Since the VDD pin is not connected, it will work.  However, space is more limited in the C64-C cases and it is unlikely you will be able to close the machine with this board installed.

## What about the 6567R56A?
The resolution and cycle schedule (and hence timing) is slighly different in the 6567R56A. It generates a composite signal slightly out of range from the expected 15.734khz horizontal frequency for NTSC (15.980khz). Some composite LCD monitors don't like this and these chips produce unwanted artifacts. CRTs, however, are more forgiving. The composite video quality is generally not as good as the 6567R8. The FPGA core does support the 6567R56A with a configuration change.

## What about the 6569R1/R3/R5?
There are subtle differences between the different revisions mostly to due with luminance values. Since the palette is configurable (with at least 4 bits of precision), it's not worth adding configuration for these revisions.

## Do I need a functioning clock circuit on my board?
No. The clock input pins (color and dot) are not connected. The board comes with its own clock and can switch between PAL and NTSC timing with a configuration change. (So if your C64 has died due to a malfunctioning clock circuit, this is an option to get your computer back to a working state).

## Do I need to modify my board?
No, modifications to the motherboard are not required. However, if you plan on using VGA or HDMI output, it is recommended the RF modulator be removed. The hole previously used for the composite jack may then be used for an HDMI or VGA cable. Otherwise, there is no practical way for a cable to exit the machine.

## How accurate is it?
I'm going to say 99%. I can't test every program but it supports the graphics tricks programmers used in their demos/games.  So far the results have been excellent but more testing is needed.  Also, it is possible some glitch in the real hardware could be discovered in the future that would require an update to the logic in the core.

## Will HDMI make my C64 look like an emulator?
Yes. The pixel perfect look of HDMI output will resemble an emulator. This may not be desirable by some. There is no attempt to add any video processing to make HDMI look like a CRT (scanlines, curve, etc.)  If you want the look of a CRT, you should chose the Composite/VGA options and use a real CRT.  Also, the resolution will not match an HDMI monitor's native resolution so there will always be some scaling taking place.

## Will HDMI/VGA add delay to the video output?
There is no frame buffer for video output. However, there is a single raster line buffer necessary to double the 15khz horizontal frequency. Although this adds a very small delay, it is a tiny fraction of the frame rate and is imperceivable by a human. Any latency added will be from the monitor you use. Most TVs have a 'game mode' that turns off extra processing that can introduce latency.

## Why not just buy a real one?
If you need a VIC-IIe to replace a broken one, you should just buy one off eBay. This project is for fun/interest and would certainly cost more than just buying the real thing.

## Will there be any extras?
Maybe. Here is the list of extras I would like to add:
1) a configurable palette
2) a math co-processor
3) a new video mode to play around with

## Demos Tested
| Demo | Issues
|--|--|
| Comaland | None
| Edge Of Disgrace | i) terminator scroll rhs glitch (same as VICE)
| Krestage | None
| Krestage 2 | None
| Krestage 3 | None
| Lunatico | None
| Reflection | TBD
| StarWars | None
| Uncensored | Rogue pixel at bottom of the 'ski hill'
| We Are New | TBD
| Monumentum | TBD

## Games Tested
| Game | Media | Issues | Game | Media | Issues
|--|--|--|--|--|--|
| Ghostbusters | Disk | None | Raid On Bungelin Bay | Disk | None
| Ghosts 'n Goblins | Disk | None | Impossible Mission | Disk | None
| Ms. Pacman | Cart | None | | |
| Jupiter Lander | Cart | None | | |
| Choplifter | Cart | None | | |
| Super Zaxxon | Cart | None | | |
| Jumpman Jr. | Cart | None | | |

