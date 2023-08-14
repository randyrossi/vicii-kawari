#!/bin/sh
. ./config.sh
NAME=Spartan6567R8
xrandr --delmode $OUTPUT $NAME
xrandr --newmode $NAME 32.72 840 880 958 1040 506 508 524 526 -hsync -vsync
xrandr --addmode $OUTPUT $NAME
xrandr --output $OUTPUT --mode $NAME
