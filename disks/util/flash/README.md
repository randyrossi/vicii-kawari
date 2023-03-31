# Where are the firmware releases?

See [FIRMWARE](../../../doc/FIRMWARE.md) for latest firmware files.

# How to make a flash disk (Trion)

1. Build a vicii.hex file.  See boards/rev_4H or boards/rev_4G directories.
2. Use efinity_pgm.sh to create a multi.hex file.  Slot 0 gets the fallback image.  Slot 2 gets the active image. (They can be different versions)
3. Use multi_hex_to_bit tool to convert the multi.hex file into a .bit file.  It must be named according to the naming convention expected in Makefile.inc.
4. Edit the Makefile.MAINLH, Makefile.MAINLG-DVI, Makefile.MAINLG-RGB (etc) file to build either a golden (fallback) or multiboot (active) flash disk.  The start address and type will change.
5. Use make -f Makefile.VARIANT zip to create the flash disks and zip file.

# Beta Board

The beta-board was sent to 10 individuals as part of a beta program for testing.
It has the label VICII-Kawari-B X16-M9516-W25Q16-001

NOTE: 0.1 fallback images on the first beta boards had a flashing bug. If your active image reports 0.2, you should flash 1.4 image as well as 1.5.

# Final Spartan6 Large (Fully Featured) Board

This board is the final hardware revision using the Spartan6 FPGA. It has the label VICII-Kawari-4L X16-M9516-W25Q16-002.

# Final Trion Mini (Luma/Chroma only) Board

This board is labeled VICII-Kawari LH Revision 1.3 or 1.4

NOTE: Rev1.3's bottom socket cannot be removed. Rev1.4's bottom socket can be removed.

# Final Trion Large (Luma/Chroma+DVI/RGB) Board

This board is labeled VICII-Kawari LG Revision 1.2
