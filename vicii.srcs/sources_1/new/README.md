Compile and install verilator
sudo apt-get install pulseview

WARNING: Old pulseview (0.4.0) has VCD import bugs.  v0.5.0 works.

make
make run
make view


Notes

Created two clock sources using MMCM
4x dot clock = 32.727272
4x color clock = 14.318181
Turn off phase alignment

From 4xdot div by 4 to get dot 8.181818 Mhz
From 4xcol div by 4 to get col ref 3.58 Mhz
From 4xdot div by 32 to get phi 1.022 Mhz
