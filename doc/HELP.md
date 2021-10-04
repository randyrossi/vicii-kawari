Back to [README.md](../README.md)

# VICII-Kawari Troubleshooting

## I changed some video settings and now I have no picture

Some display settings can cause HDMI/VGA or Analog RGB to no longer output a video signal compatible with your monitor.  

   RGB 15khz
   RGB 1X Width
   RGB CSYNC

There are several ways to restore the device to known good settings:

### Option 1

   LOAD "CONFIG",8,1
   RUN
   Press 'D'
   Press 'S'
   Power-cycle the machine.

   You can do this 'blind' if the display isn't working.

### Option 2

   Briefly connect the two jumper pads on the VICII-Kawari board labeled 'CFG RESET'
   Power-cycle the machine.

### Option 3

   POKE 53311,86
   POKE 53311,73
   POKE 53311,67
   POKE 53311,50
   POKE 53311,96
   POKE 53305,0
   POKE 53307,0
   Power-cycle the machine.

   Again, this can be done 'blind' as long as you don't make typos.

## My Kawari has booted into an old version (0.#)

   If your flash program was interrupted and/or did not complete successfully, your device may boot into a 'fallback' image.  These images have major version #0.  You can find the latest flash utility disk and update the device.  It should then boot into the latest version.

   Note that if your device has booted into the fallback image, it may boot slower and 'miss' the reset line going high on some machines.  This is because it takes a bit of time for the FPGA to detect it has not successfully booted into the main image.  If you find you get a black screen, 'soft' reset your C64 with a reset switch (Pi1541/Cartridge).  If you don't have a reset switch, you can temporarily short user port pins 1 and 3.

