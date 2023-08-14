#!/bin/sh
. ./config.sh
NAME=Spartan6567R56A
xrandr --delmode $OUTPUT $NAME
xrandr --newmode $NAME 32.72 824 864 940 1024 504 506 522 524 -hsync -vsync
xrandr --addmode $OUTPUT $NAME
xrandr --output $OUTPUT --mode $NAME
