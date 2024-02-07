# Download

Download here: [Utility and Demo Disks](http://accentual.com/vicii-kawari/downloads/prog)

* NOTE: The Kawari Inside demo requires a 1541 (or Pi1541). SD2IEC devices are not compatible with the fast loader.

# VIC-II Kawari Demo/Util Disks

The programs on these disks require a VIC-II Kawari. They will not function on a stock C-64.

## Index

Demo Program | Description
--------|------------
demo/ball | A spinning ball using color cycling.
demo/hires/grogu | A demonstration of the 320x200 16 color graphics mode 
demo/hires/horse | A demonstration of the 640x200 4 color graphics mode 
demo/split | Demonstration of hi/lo res split screen using raster IRQ 
demo/racer80 | 80 column basic program (requires vmem-49152)

Utility Program | Description
----------------|------------
config/config   | Kawari configuration utility. Set video params and standard.
config/rgbed    | RGB color editor
config/comped   | Luma/Chroma/Amplitude color editor
config/eepromed | EEPROM utility.
config/qs       | Quick switch utility. Fast to load and switch video standard.
80col-51200     | Enable 80 column BASIC mode. 2k resides at $c800.
vmem-49152      | Utility functions to access 80 column screen memory from basic
novaterm        | Novaterm 9.6c 80 column driver. Copy 80col.kawari to novaterm disk.
flash           | Flash disk builder utility.
tests/regted    | Test suite for extended registers
tests/rgbtest   | Test util to check analog RGB on oscilloscope
tests/lumatest  | Test util to check luma signal on oscilloscope
tests/mathtest  | Math function test suite

krps.d64    | Description
------------|-------------
krps-rgb    | RGB version of experimental raster line palette switch
krps-hsv    | HSV version of experimental raster line palette switch
