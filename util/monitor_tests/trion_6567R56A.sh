#!/bin/sh
. ./config.sh
NAME=Trion6567R56A
xrandr --delmode $OUTPUT $NAME
xrandr --newmode $NAME 26.59 762 766 830 832 504 506 522 524 -hsync -vsync
xrandr --addmode $OUTPUT $NAME
xrandr --output $OUTPUT --mode $NAME
