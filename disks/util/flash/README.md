# Where are the firmware releases?

See [FIRMWARE](../../../doc/FIRMWARE.md) for latest firmware files.

# build_efinix.sh

Builds all Mini/Large flash disks for both active and fallback images.

# build_spartan.sh

Builds beta and final spartan large flash disks for both active and fallback.

# Beta Board

The beta-board was sent to 10 individuals as part of a beta program for testing.
It has the label VICII-Kawari-B X16-M9516-W25Q16-001

NOTE: 0.1 fallback images on the first beta boards had a flashing bug. If your active image reports 0.2, you should flash 1.4 image as well as 1.5.

# Final Spartan6 Large (Fully Featured) Board

This board is the final hardware revision using the Spartan6 FPGA. It has the label VICII-Kawari-4L X16-M9516-W25Q16-002.

# Final Trion Mini (Luma/Chroma only) Board

This board is labeled VICII-Kawari LH Revision 1.3, 1.4, 1.5

NOTE: Rev1.3's bottom socket cannot be removed. Rev1.4's bottom socket can be removed.

NOTE: Rev1.5 has an extra pad for exporting the dot clock. It can be done with revs before 1.5 but you have to solder a wire to an IC pin.

# Final Trion Large (Luma/Chroma+DVI/RGB) Board

This board is labeled VICII-Kawari LG Revision 1.2


# Build Notes

## Build

    ./build.sh sweep

## Check timing

    cd run_sweep_####
    ../check_sweep.sh

## Find good seed

    Pick one with no timing issues

## Mark seed

    touch run_sweep_####/SEED#

## Repeat for all variants/builds (there are 6)

## Copy to single folder

    DEST: hex/single/VER/see_nameing_convention.hex

## Use efinix_pgm.sh to generate multi hex

    SRC : hex/single/VER/see_nameing_convention.hex
    DEST: hex/multi/VER/see_nameing_convention.hex

    Slot 0 and Slot 2 point to same single hex file.

## Make zips

   ./build_efinix.sh
