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
0.1 - Golden     - shipped with most beta boards
0.2 - Multiboot  - shipped with most beta boards
0.3 - Golden     - shipped with some beta boards
0.4 - Multiboot  - shipped with some beta boards
0.7 - Golden     - Fixes flashing issue on beta board fallback image
0.8 - Multiboot  - First published update for beta board
