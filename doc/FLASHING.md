Back to [README.md](../README.md)

# VIC-II Kawari Firmware Flash Guide

There are a number of ways you can flash new firmware to the Kawari board:

## D81 file + KungFuFlash (fastest/easiest)

Use a KungFuFlash card and select the .D81 disk you copied to the sdcard. Select FLASH.PRG to start.  Say 'No' when prompted to use a fast loader.  Just press enter when prompted to swap disks.

## D64 files + Real Disk Drive (Slow)

You can use a real 1541 disk drive provided you create physical disks from the provided .d64 files. There are a number of utility programs that can do this.  Once created, insert DISK 1 and type 

```
LOAD "*",8,1
RUN
```

You may enable the fast loader or use a fast load cartridge with a real 1541 drive.

## D64 files + Pi 1541 Drive

Same instructions as above except you MUST remember to mount ALL disks before starting the flash operation.  If you forget, don't power off the machine.  Instead, soft-reset and try again.  The fast loader (or cartridge) will work with the Pi 1541.

## D81 files + Pi 1541 Drive

Note: Neither the fast load cartridge nor the built in fast loader will work with D81 files.  The .D81 disk is included as a convenience to avoid having to disk swap.  Just press RETURN when prompted to insert the next disk.  If you are using a Pi1541, you must install the 1581 ROM, otherwise the Pi1541 will not be able to mount the disk.

## D64 files + SD2IEC (slow)

You can use an SD2IEC to flash the Kawari as well but must ensure you are able to swap disks using the 'Next' button.  If your SD2IEC does not have a 'Next' button, it cannot be used.  Make a new directory on your sdcard ('flash' for example).  Then place all *.d64 and the autoswap.lst file into the directory. Now do the following:

```
OPEN 15,8,15,"CD//flash":CLOSE15
**press the NEXT button on the SD2IEC**
LOAD"*",8,1
RUN
```

NOTE: It is a very good idea to check your 'Next' button actually works before trying to flash disks.  If it fails to work after you've started the flash process, you won't be able to finish the flash operation and will have to fall back to the factory default image to try again.

## D81 file + SD2IEC (slow)

If your SD2IEC supports it, you can mount the single D81 disk.  However, the fast loader cannot be used.  A fast loader cartridge may work if the SD2IEC supports it (ie. Epyx Fastload).  This method is likely to be very slow.

