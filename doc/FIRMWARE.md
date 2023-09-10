Back to [README.md](../README.md)

# READ THIS BEFORE FLASHING!

When using the individual .D64 files, please make sure you are actually able to swap disks! (using SD2IEC, Pi1541, etc).  For the Pi1541, you must mount ALL DISKS into your queue before starting the flash operation.  For the SD2IEC, please make sure your 'Next' button works as expected.  For the .D81, you can just press RETURN when prompted to swap disks.

If you begin flashing and are unable to swap disks, soft reset the machine, fix the issue and try again.  If you power off the machine without a successfuly flash after it was started, you will have to boot into the **fallback** image to fix it.  See [FLASHING.md](FLASHING.md) for the different options on flashing these files.

# Active Image updates

These firmware files will update the **active** image on your board.  This is probably what you want to do...
Board         | Firmware Link| Description
--------------|------|---------
Trion Mini    | [1.16](https://accentual.com/vicii-kawari/downloads/flash/LH/kawari_flash_1.16_MAINLH_multiboot.zip) | For the 'Mini' board.
Trion Large w/ DVI   | [1.17 with Non-Std DVI ](https://accentual.com/vicii-kawari/downloads/flash/LG/kawari_flash_1.17_MAINLG-DVI-29MHZ-U_multiboot.zip) | Enables DVI output via the micro-HDMI port. The RGB header is not enabled in this build (however, the CLK pin will be enabled with a dot clock signal). Regular Composite/S-Video out the regular rear jack is always available.
Trion Large w/ DVI (480p/576p - Scaled) | [1.17 with 480p/576p DVI ](https://accentual.com/vicii-kawari/downloads/flash/LG/kawari_flash_1.17_MAINLG-DVI-27MHZ-S_multiboot.zip) | Same as above except uses more standard video modes and may result in better compatibility with some monitors that don't like to sync to the default firmware.
Trion Large w/ RGB   | [1.16 with RGB ](https://accentual.com/vicii-kawari/downloads/flash/LG/kawari_flash_1.16_MAINLG-RGB_multiboot.zip) | Enables RGB output via the RGB header. DVI output is disabled in this build. Regular Composite/S-Video out the regular rear jack is always available.
Spartan Large | [1.15](https://accentual.com/vicii-kawari/downloads/flash/LD/kawari_flash_1.15_MAINLD_multiboot.zip) | Only 7 of these boards were produced. Both DVI and RGB are enabled. (This model is unlikely to work with the EVO64)
Spartan Large (Beta) | [1.15](https://accentual.com/vicii-kawari/downloads/flash/T/kawari_flash_1.15_MAIN_multiboot.zip) | Only 10 of these boards were produced. Both DVI and RGB are enabled. (This model is unlikely to work with the EVO64)
# Fallback Image updates

These firmware files will update the **fallback** image on your board.  The fallback image is used to restore a failed active image and is booted only when certain pads are shorted during a cold boot.  Versions before 1.14 were not compatible with systems with SRAM.  If you intend on using the board with SRAM, it may be a good idea to also update your fallback image.  That way, the board will still boot into fallback mode on those systems.  To check what version your fallback image is, load the CONFIG util after booting the device into fallback mode.  You can boot the device into fallback mode by shorting the fallback pads together during a cold boot (see [VARIANTS.md](VARIANTS.md)) for how to do that on each device type.

Board         | Firmware Link| Description
--------------|------|---------
Trion Mini    | [1.16](https://accentual.com/vicii-kawari/downloads/flash/LH/kawari_flash_1.16_MAINLH_golden.zip) | Fallback for the Mini board.
Trion Large w/ DVI   | [1.17 with Non-Std DVI ](https://accentual.com/vicii-kawari/downloads/flash/LG/kawari_flash_1.17_MAINLG-DVI-29MHZ-U_golden.zip) | Fallback for the large board.  (There is no RGB enabled fallback, always DVI.)
Trion Large w/ DVI (480p/576p - Scaled) | [1.17 with 480p/576p DVI ](https://accentual.com/vicii-kawari/downloads/flash/LG/kawari_flash_1.17_MAINLG-DVI-27MHZ-S_golden.zip) | Fallback for the large board but with the 'more standard' 480p/576p video modes.  (There is no RGB enabled fallback, always DVI.)

# Specialty Builds

WARNING: These specialty builds are provided for fun/experimentation purposes only.  Please flash them only if you know exactly what you're doing.

Board         | Firmware Link| Description
--------------|------|---------
Trion Mini (Board REV 1.2-1.4) | [1.16](https://accentual.com/vicii-kawari/downloads/flash/LH/kawari_flash_1.16_MAINLH-DOTC-1.2_multiboot.zip) | A custom 'active' image build that exports a dot clock signal out Pin 3 of the 74LS06D chip.  This can be passed through a 33 Ohm resistor into the motherboard to provide a dot clock for both NTSC and PAL while still using the on board oscillators. Please only flash this if you know what you are doing.
Trion Mini (Board REV 1.5) | [1.16](https://accentual.com/vicii-kawari/downloads/flash/LH/kawari_flash_1.16_MAINLH-DOTC-1.5_multiboot.zip) | Same as above except the dedicated CLK pad is used instead of having to hack into the 74LS06D.  NOTE: A 33ohm resistor is already on this version of the board (unlike the large).  Please only flash this if you know what you are doing.

# PSA - 2023/03/31

There was a firmware version 1.6 + Dot Clock mod that was released for the Mini.  Flashing this version would get your board 'stuck' on 1.6 even after you flashed active image updates.  This is because it was set to flash to the fallback area by mistake.  To fix this, just flash the **fallback** mini update above.  Then your board will boot to the last active image you flashed and your fallback switch will function again.

# HELP! Both my fallback and active images won't boot!

You may have to restore the board using a programmer.

For Trion boards, you can use a Raspberry Pi. See [FLASHING WITH A RASPBERRY PI](../util/raspi/README.md).

For Spartan6 boards, a Xilinx programmer and ISE 14.7 is required to flash an .mcs file. Contact me if you need this.

# Firmware History

Download firmware updates here: [README.md](../disks/util/flash/README.md)

Version | Notes
--------|--------
1.17    | Added 480p/576p version of DVI firmware for monitors that don't like to sync to the default. Also cenetered stuff better.
1.16    | Fixed 2 blitter bugs. Added IRQ status/control bits for DMA operations.
1.15    | Fixed some DVI signal stability issues. Also made RGB H/V sync match that of composite.
1.14    | Composite/s-video was shifted from original - fixed (NTSC/PAL)<br>Analog RGB video was shifted 10 pixels - fixed (NTSC/PAL)<br>Fixed B/W only image when using motherboard PAL clock (some monitors)<br>Made luma vertical blanking closer to NTSC/PAL spec<br>Add NTSC50 and PAL60 options (YMMV)<br>Fix dot clock not available on DVI builds (large)<nr>Set addr/moved CAS/RAS fall times earlier in cycle for some slower DRAMs<br>Single build that works with both DRAM and static ram modules (DIY Chris, Saruman)
1.10    | Active image for Large Trion
1.9     | Fallback image for Large Trion
1.8     | Fixes #6 - Analog RGB issue, NTSC VGA picture was dark or had no blue
1.6     | Intermediate dotclock or static ram build<br>Identical to 1.5<br>To be replaced soon.
1.5     | Active image (initial release)<br>Identical to 1.4
1.4     | Fallback image (initial release)<br>First firmware with all features (blitter, dma, 160x200, white line, etc)<br>Does not work with SaRuMan + 250407<br>DMA xfer does not work on short boards (but short boards not recommended anyway)
0.8     | Active image shipped on some beta boards (model T)
0.7     | Fallback image shipped on some later beta boards (model T)<br>Fixes flash bug
0.4     | Active image shipped on some later beta boards (model T)
0.3     | Fallback image shipped on some later beta boards (model T)
0.2     | Active image shipped on first beta board (model T)<br>Can be used to flash fallback image if needed to fix flash bug on 0.1
0.1     | Fallback image shipped on first beta board (model T)<br>Had a flashing bug and should be overwritten with latest fallback image
