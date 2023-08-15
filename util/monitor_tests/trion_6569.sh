#!/bin/sh
. ./config.sh
NAME=Trion6569
xrandr --delmode $OUTPUT $NAME
xrandr --newmode $NAME 29.56 800 809 937 945 528 538 542 624 -hsync -vsync
xrandr --addmode $OUTPUT $NAME
xrandr --output $OUTPUT --mode $NAME
