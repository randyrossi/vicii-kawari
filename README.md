# VIC-IIe 6567/6569 Replica Project

## What is this?
This is a VIC-IIe 6567/6569 replacement project.  VIC-IIe video chips are found in Commodore 64 home computers. This project contains:

1) an open source VIC-IIe 6567/6569 FPGA core written in Verilog
2) schematics for interfacing the FPGA core with a real C64 address and data bus through the VIC-II motherboard socket
3) schematics for video output (composite or VGA) from the FPGA core

Together, these components can replace all the functions of a real VIC chip including DRAM refresh, PHI2 clock source for the CPU and, of course, video output.

## Can I build one?
It's possible but would be expensive, time consuming, bulky and impractical as any sort of convenient replacement.  The only working configuration currently uses a CMOD-A7 35T development board (Artix-7).  The FPGA is about 20x larger than is required.  A much smaller FPGA will be used once the core is fully developed.  It's too early in the project to support anyone attempting to build one on their own.

## Is there a PCB?
No.  A test harness has been constructed using breadboard-able components and jumpers wired directly into the C64 VIC-II socket. A PCB may be developed later.

## How accurate is it?
I'm going to say 99%. I can't test every program but it supports the graphics tricks programmers used in their demos/games.  So far the results have been excellent but more testing is needed.  Also, it is possible some glitch in the real hardware could be discovered in the future that would require an update to the logic in the core.

## What kind of video options will there be?
Right now, there are two video options:  a Sony CXA1645P composite encoder IC or GERT VGA666 adapter board.  Later revisions may produce luma/chroma directly from the FPGA using DACs.  Even later revisions may support HDMI output.

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
| Uncensored | None
| We Are New | TBD

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

## TODO

* timings/outputs for external HDMI encoder
* adjustable timings & v/h offsets for VGA
