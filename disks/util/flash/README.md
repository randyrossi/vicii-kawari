Releases
--------

# Beta Board

The beta-board was sent to 10 individuals as part of a beta program for testing.
It has the label VICII-Kawari-B X16-M9516-W25Q16-001

[0.7 fallback](https://accentual.com/vicii-kawari/downloads/flash/T/kawari_flash_0.7_T_golden.zip) \
[0.8 active](https://accentual.com/vicii-kawari/downloads/flash/T/kawari_flash_0.8_T_multiboot.zip)

NOTE: The 0.7 fallback image fixes a problem with 0.1 fallback image which was not capable of flashing updates. If your CONFIG util reports 0.2, you should flash this image. Then flash 0.8. Otherwise, you can just flash 0.8.

# Final Spartan6 Large (Fully Featured) Board

This board is the final hardware revision using the Spartan6 FPGA. It has the label VICII-Kawari-4L
X16-M9516-W25Q16-002.

[1.1 active](https://accentual.com/vicii-kawari/downloads/flash/LD/kawari_flash_1.1_LD_multiboot.zip)

Notes
-----

Generate Kawari flash disks with this util

To generate a multiboot (active) image, change Makefile params as follows:

    START_ADDRESS=512000
    SOURCE_IMG=kawari_multiboot_$(VERSION).bit

To generate a golden (fallback) image, change Makefile params as follows

    START_ADDRESS=0
    SOURCE_IMG=kawari_golden_$(VERSION).bit

Golden images should not be updated normally. But the very first golden image on the beta boards had a flashing bug.

History
-------

Version | Type | Notes
--------|------|------
0.1 | Fallback | shipped with most beta boards
0.2 | Active   | shipped with most beta boards
0.3 | Fallback | shipped with some beta boards
0.4 | Active   | shipped with some beta boards
0.7 | Fallback | fixes flashing issue on beta board fallback image
0.8 | Active   | first published update for beta board
