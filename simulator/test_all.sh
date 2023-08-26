#!/bin/sh

# Run through different clock pixel and
# scaling configs

mkdir -p screenshots

make clean
PAL_RES=29MHZ NTSC_RES=26MHZ make
vicsim -w -c 1 -y
mv screenshot.bmp screenshots/6569-29MHZ-U.bmp
vicsim -w -c 0 -y
mv screenshot.bmp screenshots/6567R8-26MHZ-U.bmp
vicsim -w -c 2 -y
mv screenshot.bmp screenshots/6567R56A-26MHZ-U.bmp

make clean
PAL_RES=27MHZ NTSC_RES=26MHZ make
vicsim -w -c 1 -y
mv screenshot.bmp screenshots/6569-27MHZ-U.bmp

make clean
PAL_RES=27MHZ NTSC_RES=26MHZ SCALED=y make
vicsim -w -c 1 -y
mv screenshot.bmp screenshots/6569-27MHZ-S.bmp
vicsim -w -c 0 -y
mv screenshot.bmp screenshots/6567R8-26MHZ-S.bmp
vicsim -w -c 2 -y
mv screenshot.bmp screenshots/6567R56A-26MHZ-S.bmp
