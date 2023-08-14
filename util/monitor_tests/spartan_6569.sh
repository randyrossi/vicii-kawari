#!/bin/sh
. ./config.sh
NAME=Spartan6569
xrandr --delmode $OUTPUT $NAME
xrandr --newmode $NAME 31.52 840 880 956 1008 604 606 622 624 -hsync -vsync
xrandr --addmode $OUTPUT $NAME
xrandr --output $OUTPUT --mode $NAME
