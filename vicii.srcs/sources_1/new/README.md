Prerequisites

    verilator
    sudo apt-get install pulseview (v0.5.0+)

Build

    make       - verilate fpga design
    make run   - generate simulation
    make logic - show logic analyser on simulation
    make view  - show frame

Design Notes

    Created two clock sources using MMCM
    4x dot clock = 32.727272 with reset
    4x color clock = 14.318181 with reset
    Turn off phase alignment

    From 4xdot div by 4 to get dot 8.181818 Mhz
    From 4xcol div by 4 to get col ref 3.579545 Mhz
    From 4xdot div by 32 to get phi 1.0227 Mhz

    Top outputs RGB222, SYNC + COLOREF
       Feeds into CX1645P composite encoder to produce luma/chroma/composite


