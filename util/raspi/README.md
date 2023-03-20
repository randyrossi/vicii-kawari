# flash.py

A utility to flash Kawari boards from Raspberry Pi.

## Enable

    sudo raspi-config
    Select "Interfacing Options"
    Select "P4 SPI"
    Answer "Yes" when asked to enable the SPI interface.
    Reboot the Pi for the change to take effect

## Top programming

    For the Mini:

    MISO  CS    +3V  RST (left side of solder bridge)
    GND   MOSI  CLK

    For the Large:

         RST (bottom pad of solder bridge)
    GND  CS
    MISO MOSI
    CLK  +3V

## Wiring

    MOSI -> PIN 19
    MISO -> PIN 21
    CLK -> PIN 23
    GND -> PIN 20
    RST (from solder bridge) -> Pin 25

## Usage

   python flash.py read|write filename size

   The files must be binary (.bit) files. Use the multi_hex_to_bit utility in the flash directory to convert .hex files to .bit.  The .hex files must be created using Efinity tools where the fallback image appears in slot 0 and the active image appears in slot 2.  The .bit files must match the expected file sizes exactly (as in the examples).

## Examples

#### Flash Mini

   python flash.py write mini.bit 1318912

#### Read Mini

   python flash.py read read_back.bit 1318912

#### Flash Large

   python flash.py write large.bit 1359872

#### Read Large

   python flash.py read read_back.bit 1359872
