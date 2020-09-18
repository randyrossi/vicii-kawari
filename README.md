# VIC-IIe 6567/6569 Replica Project

## What is this?
This is an experimental VIC-IIe 6567/6569 replacement project.  VIC-IIe video chips are found in Commodore 64 home computers. This project contains the following:

1) an open source VIC-IIe 6567/6569 FPGA core written in Verilog
2) schematics for interfacing the FPGA core with a real C64 address and data bus through the VIC-II C64 motherboard socket
3) schematics for an optional composite video output adapter (headers for GERT VGA 666 or ICE Breaker HDMI modules also supported)

Together, these components can replace all the functions of a real VIC-IIe chip including DRAM refresh, light pen interrupts (real CRT only), PHI2 clock source for the CPU and, of course, video output.

## How accurate is it?
I'm going to say 99%. I can't test every program but it supports the graphics tricks programmers used in their demos/games.  So far the results have been excellent but more testing is needed.  Also, it is possible some glitch in the real hardware could be discovered in the future that would require an update to the logic in the core.

## What kind of video options will there be?
Right now, there are three video output options:

    1) a custom composite adapter based on the Sony CXA1645P composite encoder IC (separate luma/chroma also available)
    2) a GERT VGA666 adapter board 
    3) an ICEBreaker Pmod Digital Video Interface adapter for HDMI

The VGA and HDMI modes are not standard so they may not work on older monitors/TVs.

## Can I build one?
It's possible but would be expensive, time consuming, bulky and impractical as any sort of convenient replacement.  The only working configuration currently uses a CMOD-A7 35T development board (Artix-7).  The FPGA is about 20x larger than is required.  A much smaller FPGA will be used once the core is fully developed.  It's too early in the project to support anyone attempting to build one on their own.

## Is there a PCB?
No.  A test harness has been constructed using breadboard-able components and jumpers wired directly into the C64 VIC-II socket. A PCB may be developed later.

## Why not just buy a real one?
If you need a VIC to replace a broken one, you should just buy one off eBay. This project is for fun/interest and would certainly cost more than just buying the real thing.  It may turn into something you can build or buy, but it's too early to tell right now.

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

