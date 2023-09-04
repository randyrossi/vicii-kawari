#!/bin/sh

# Run through different clock pixel and
# scaling configs

mkdir -p screenshots

# Unscaled
make clean
PAL_RES=29MHZ NTSC_RES=26MHZ make
vicsim -q -w -c 1 -y
convert screenshot.bmp screenshot.png
mv screenshot.png screenshots/6569-29MHZ-U.png
vicsim -q -w -c 0 -y
convert screenshot.bmp screenshot.png
mv screenshot.png screenshots/6567R8-26MHZ-U.png
vicsim -q -w -c 2 -y
convert screenshot.bmp screenshot.png
mv screenshot.png screenshots/6567R56A-26MHZ-U.png

# Scaled
make clean
PAL_RES=27MHZ NTSC_RES=26MHZ SCALED=y make
vicsim -q -w -c 1 -y
convert screenshot.bmp screenshot.png
mv screenshot.png screenshots/6569-27MHZ-S.png
vicsim -q -w -c 0 -y
convert screenshot.bmp screenshot.png
mv screenshot.png screenshots/6567R8-26MHZ-S.png
vicsim -q -w -c 2 -y
convert screenshot.bmp screenshot.png
mv screenshot.png screenshots/6567R56A-26MHZ-S.png
