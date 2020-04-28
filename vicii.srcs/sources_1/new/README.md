Prerequisites

    verilator
    sudo apt-get install pulseview (v0.5.0+)

Build

    make       - verilate fpga design
    make run   - generate simulation
    make logic - show logic analyser on simulation
    make view  - show frame

FPGA Design Notes

    Created two clock sources using MMCM
    4x dot clock = 32.727272 with reset
    4x color clock = 14.318181 with reset
    Turn off phase alignment

    From 4xdot div by 4 to get dot 8.181818 Mhz
    From 4xcol div by 4 to get col ref 3.579545 Mhz
    From 4xdot div by 32 to get phi 1.0227 Mhz

    Top outputs RGB222, SYNC + COLOREF
       Feeds into CX1645P composite encoder to produce luma/chroma/composite

Usage

   Use the -z option to have the simulator wait for a IPC request from
   our modified VICE-3.4 code to shadow it's vic.  See vicii-vice-3.4
   repo.

   ./obj_dir/Vtop -z -v

   Then run the modified VICE code to act as the sender.

   Capture can be started by poking $d3ff to set capture flags.

   POKE 54271,1 - Set bit 1 enables FPGA sync
   POKE 54271,3 - Set bit 2 disables FPGA sync (auto clears bit 1)

   When sync is enabled, VICE will single step the fpga design 16 half cycles
   after every CPU cycle.  If a write or read to/from a VIC register happens,
   this also sets address, data, ba, ce, rw lines appropriately so the fpga
   eval can operate on those values.

   You can keep VICE running and start/stop multiple captures. You have to end
   the fpga sync in a fairly short time or else you will generate too much
   data to view at once in pulseview.  It also takes a really long time
   to sync one whole frame as the fpga is evaluated every half dot clock cycle.


