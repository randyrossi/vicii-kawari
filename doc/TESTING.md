# Software Testing

## Flash Test

Test                      | Check
--------------------------|----------------------
Load                      | Flash identified, Verify 1.0
Erase 4K@512000           | Verify 0xff
Boots to golden           | Verify 0.9
Flash multiboot           |
   Try wrong variant      | Get warning
   Try wrong disk         | Retry forever
Reboot                    | Verify 1.0
Verify golden             | Should succeed

# Test Matrix For New Hardware

Check | Tool | Result
------|-------|------
Done LED Lights Up | |
Boot opposite standard on uninitialized board | Temp jumper switch
On board oscillator for NTSC | Manual check |
On board oscillator for PAL | Manual check |
Motherboard oscillator for native std| Manual check |
Red resistor ladder | RGBTEST |
Green resisor ladder | RGBTEST |
Blue resistor ladder | RGBTEST |
Luma resistor ladder | LUMATEST |
Reset detect | Ball demo + soft reset |
Spi lock detect | CONFIG |
Extensions lock detect | CONFIG |
Save lock detect | CONFIG |
Init board as PAL & Reboot | CONFIG |
Eeprom check | EEPROM UTIL |
Boot opposite standard w/ hw switch | Temp jumper switch |
Eeprom check again | EEPROM UTIL |
80 Column Mode | 80COLUMN-51200 |
Flash test | FLASHTEST |
Math test | MATHTEST |
Regs test | REGSTEGS |
CSYNC | CONFIG |
HPOL | CONFIG |
VPOL | CONFIG |
NATIVEX | CONFIG |
15KHZ | CONFIG |
RASTERLINES ON + BOOT| CONFIG |
RASTERLINES OFF + BOOT| CONFIG |
Cfg Reset | Jumper |
