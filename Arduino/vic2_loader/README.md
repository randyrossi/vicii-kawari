VICII-Kawari Loader
-------------------

This is the VICII-Kawari arduino loader.  It is based off the
Mojo V3 arduino loader.  The Mojo V3 add on must be installed
into the Arduino IDE.

The loader will read the bitstream from flash and program the
FPGA at boot.  Then it enters a config and command loop.  

Config changes are broadcast by the FPGA over serial. If
the microcontroller sees a config value that does not match
the last persisted value, it will change it to be picked
up by next boot.

Commands can be written to the serial interface across a
USB connection from the PC.

Commands
--------
reset - Reset all config values to default



Note: The MojoV3 prototype boards did not easily program with the
new bootloader.  I had to connect the RESET and GROUND pins on the
underside of the MojoV3, then use another Arduino as an ISP and
program the bootloader with the MojoV3 bootloader.  Then uploading this
sketch started working.  It could have been the bootloader was not up to
date on my MojoV3 board.
