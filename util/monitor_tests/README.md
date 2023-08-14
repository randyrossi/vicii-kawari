# HOWTO

These scripts are meant to be used on a Linux machine to test whether a
monitor/TV is likely to accept the Kawari's custom resolutions.  NOTE: This
is not a foolproof test.  It's still possible these modes work from your
Ubuntu machine but still fail from the Kawari device (especially the 50hz
modes).

EDIT config.sh and set the OUTPUT and DEFAULT_MODE variables
to match the display device output and mode reported by 
xrandr.  This is the normal desktop mode you are currently using.

Use ./to_default.sh to reset back after having tried one of the
custom modes.  You must revert back to your normal desktop mode
before switching to a different mode to test.

## For Spartan devices:

./spartan_6569.sh
./spartan_6567R56A.sh
./spartan_6567R8.sh

## For Trion devices (firmware 1.17+):

./trion_6569.sh
./trion_6567R56A.sh
./trion_6567R8.sh

