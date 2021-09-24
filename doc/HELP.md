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
   POKE 53305,255
   POKE 53307,0
   Power-cycle the machine.

   Again, this can be done 'blind' as long as you make typos.
