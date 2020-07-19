# VIC-IIe 6567/6569 Replica Project

## What is this?
This is an open source VIC-IIe 6567/6569 core written in Verilog.  This VIC core can be integrated with a real C64 bus through the VICII socket with the right supporting circuitry.  It can replace the functions of a real VIC chip including DRAM refresh, PHI2 clock source for the CPU and, of course, video output with one of the available video output options.

## Can I build one?
It's possible but would be expensive, time consuming, bulky and impractical as a convenient replacement.  The only configuration available as of today uses a CMOD-A7 35T development board (Artix-7) with a supporting composite encoder IC.  This FPGA is about 20x larger than is required.  We will migrate to a much smaller FPGA once the core is fully developed.  Also, later revisions may produce luma/chroma directly from the FPGA using DACs.  Even later revisions may support VGA or DVI output.  It's too early in the project to support anyone attempting to build one on their own.

## Is there a PCB?
No.  A test harness has been constructed using breadboard-able components and jumpers wired directly into the C64 VICII socket. Once the core is stable, we will look into designing a PCB and/or video output options.

## How accurate is it?
We're going to say 99% at the moment. We can't test every program but it supports all the graphics tricks programmers used in their demos/games.  So far the results have been excellent.  However, it's always possible some future glitch in the real hardware could be discovered that would require an update to replicate it here.

## Why not just buy a real one?
If you need a VIC to replace a broken one, you should just buy one off eBay. This project is for fun/interest.  It may turn into something you can build or buy, but it's too early to tell right now.

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

## Demos Tested
| Demo | Issues
|--|--|
| Comaland | None
| StarWars | None
| Lunatico | None
| Edge Of Disgrace | i) terminator scroll rhs glitch (same as VICE), ii) colored boxes sequence vertical bar
| Krestage | None
| Krestage 2 | None
| Krestage 3 | TBD
| Uncensored | i) colored square toss small glitch near right, ii) skihill not correct, iii) crash after skiihill?
| We Are New | TBD
| Reflection | TBD

## TODO

* timings/outputs for external HDMI encoder
