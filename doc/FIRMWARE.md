Back to [README.md](../README.md)

# Firmware Downloads

Board         | Main | DotClock | Static RAM | MK-II
--------------|------|----------|------------|-------
Spartan β Large | [1.5](https://accentual.com/vicii-kawari/downloads/flash/T/kawari_flash_1.5_T_multiboot.zip) | [1.8](https://accentual.com/vicii-kawari/downloads/flash/T/kawari_flash_1.8_DOTC_T_multiboot.zip) | [1.6](https://accentual.com/vicii-kawari/downloads/flash/T/kawari_flash_1.6_SARUT_multiboot.zip) | N/A
Spartan Large | [1.8](https://accentual.com/vicii-kawari/downloads/flash/LD/kawari_flash_1.8_LD_multiboot.zip) | [1.8](https://accentual.com/vicii-kawari/downloads/flash/LD/kawari_flash_1.8_DOTC_LD_multiboot.zip) | N/A | N/A
Trion Mini    | [1.5](https://accentual.com/vicii-kawari/downloads/flash/LH/kawari_flash_1.5_LH_multiboot.zip) | [1.6](https://accentual.com/vicii-kawari/downloads/flash/LH/kawari_flash_1.6_DOTCLH_multiboot.zip) | [1.6](https://accentual.com/vicii-kawari/downloads/flash/LH/kawari_flash_1.6_SARULH_multiboot.zip) | [1.8](https://accentual.com/vicii-kawari/downloads/flash/LH/kawari_flash_1.8_MKIILH_multiboot.zip)
Trion Large   | [1.10/DVI](https://accentual.com/vicii-kawari/downloads/flash/LG/kawari_flash_1.10_MAINLG_DVI_multiboot.zip), [1.10/RGB](https://accentual.com/vicii-kawari/downloads/flash/LG/kawari_flash_1.10_MAINLG_RGB_multiboot.zip) | N/R | [1.11/DVI](https://accentual.com/vicii-kawari/downloads/flash/LG/kawari_flash_1.11_SARULG_DVI_multiboot.zip), [1.11/RGB](https://accentual.com/vicii-kawari/downloads/flash/LG/kawari_flash_1.11_SARULG_RGB_multiboot.zip)| [1.11/DVI](https://accentual.com/vicii-kawari/downloads/flash/LG/kawari_flash_1.11_MKIILG_DVI_multiboot.zip), [1.11/RGB](https://accentual.com/vicii-kawari/downloads/flash/LG/kawari_flash_1.11_MKIILG_RGB_multiboot.zip)

# Firmware History

Download firmware updates here: [README.md](../disks/util/flash/README.md)

Version | Notes
--------|--------
1.11    | Adds NTSC_50 and PAL_60
1.10    | Active image for Large Trion
1.9     | Fallback image for Large Trion
1.8     | Fixes #6 - Analog RGB issue, NTSC VGA picture was dark or had no blue
1.6     | Intermediate dotclock or static ram build<br>Identical to 1.5<br>To be replaced soon.
1.5     | Active image (initial release)<br>Identical to 1.4
1.4     | Fallback image (initial release)<br>First firmware with all features (blitter, dma, 160x200, white line, etc)<br>Does not work with MK2<br>Does not work with SaRuMan + 250407<br>DMA xfer does not work on short boards (but short boards not recommended anyway)
0.8     | Active image shipped on some beta boards (model T)
0.7     | Fallback image shipped on some later beta boards (model T)<br>Fixes flash bug
0.4     | Active image shipped on some later beta boards (model T)
0.3     | Fallback image shipped on some later beta boards (model T)
0.2     | Active image shipped on first beta board (model T)<br>Can be used to flash fallback image if needed to fix flash bug on 0.1
0.1     | Fallback image shipped on first beta board (model T)<br>Had a flashing bug and should be overwritten with latest fallback image
