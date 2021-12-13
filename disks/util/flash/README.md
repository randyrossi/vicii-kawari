Releases
--------

[0.7 fallback](https://accentual.com/vicii-kawari/downloads/flash/kawari_flash_0.7.d64) \
[0.8 active](https://accentual.com/vicii-kawari/downloads/flash/kawari_flash_0.8.d64)

NOTE: The 0.7 fallback image fixes a problem with 0.1 fallback image which was not capable of flashing updates. If your CONFIG util reports 0.2, you should flash this image. Then flash 0.8. Otherwise, you can just flash 0.8.

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
