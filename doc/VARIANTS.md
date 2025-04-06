Back to [README.md](../README.md)

# Variants

## Mini Trion Board (Rev 1.3 / 1.4 / 1.5)

    TYPE: Mini            FPGA: T20Q144C3
    VARIANT CODE: LH      FLASH: W25Q16JVSSIM    EEPROM: M95160-DRDW8
    BUILD CODES: MAINLH MAINLH-DOTC

![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/4LH_Jumpers.png)

Jumper | Function
-------|---------
JP2    | Boot fallback firmware at cold boot (short while booting)
JP3    | Reset flash configuration to factory defaults, short at READY screen, border will turn white

NOTE: Rev 1.5 added a CLK pad to optionally export the dot clock. There is already a 33ohm resistor on the line.  This can be activated with one of the specialty builds.  Earlier rev boards can export the dot clock through Pin 3 of the 74LS06D chip but requires a 33ohm resistor.

## Large Trion Board (Rev 1.2 / 1.3)

Revision 1.2/1.3 of the Large Efinix Trion based board (200).

    TYPE: Large            FPGA: T20FBGA256
    VARIANT CODE: LG       FLASH: W25Q16JVSSIM    EEPROM: M95160-DRDW8
    BUILD CODES: MAINLG-DVI MAINLG-RGB

![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/4LG_Jumpers.png)

Jumper | Function
-------|---------
TP1&TP2| Boot fallback firmware at cold boot (short while booting)
JP2    | Reset flash configuration to factory defaults, short at READY screen, border will turn white

NOTE: The CLK pad on the analog header is always active (since v1.17) but requires an external 33ohm resistor.

# Legacy/Beta Boards

## Large Spartan 'Beta' Board (Rev B)

This board was sent to 10 BETA testers.

    TYPE: Large           FPGA: XC6SLX16-2FTG256C
    VARIANT CODE: (null)  FLASH: W25Q16JVSSIM      EEPROM: M95160-DRDW8
    BUILD CODES: MAIN

![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/3T_Jumpers.png)

## Large Spartan Board (Rev C)

Last version of the large spartan based board. Only 7 were made.  Further production of this design is unlikely due to supply issues with Spartan6.

    TYPE: Large           FPGA: XC6SLX16-2FTG256C
    VARIANT CODE: LD      FLASH: W25Q16JVSSIM     EEPROM: M95160-DRDW8
    BUILD CODES: MAINLD

![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/4LD_Jumpers.png)

