# LumaCode (Experimental)

NOTE: The mod described on this page experimental. Try at your own risk!

Kawari Mini firmare v1.17+ can generate LumaCode. LumaCode is an interface for transferring digital video from retro computers. To display a LumaCode video signal, an RGB2HDMI Raspberry Pi hat and analog companion board is required. For more information on LumaCode, see [LumaCode Overview](https://github.com/c0pperdragon/LumaCode/wiki/Overview).  I purchased my RGB2HDMI and Analog Board from [retrohackshack.com](https://retrohackshack.com/product/rgbtohdmi)

Experimental Firmware: [Mini 1.17](https://accentual.com/vicii-kawari/downloads/flash/LH/kawari_flash_1.17_MAINLH_multiboot.zip)

Utility Disk 1.6 with updated COMPED.PRG: [Utility_1.6](https://accentual.com/vicii-kawari/downloads/prog/kawari_util_1.6.d64)

You do not need the VIC-II-dizer sub-board in the VIC-II socket as you would with a genuine VIC-II chip.  The Kawari can output a signal similar to what the VIC-II-dizer outputs directly from its luma output pin (15). It's unknown at this time whether the VIC-II-dizer will work with a Kawari (please report if you have one to try).

# Switch to lumacode using COMPED

Before you begin, load COMPED.PRG and use the 'J' key to select the newly available LumaCode preset.  NOTE: You will have to enable LumaCode for EACH chip type and save the new config. LumaCode is a 'per' chip setting.  

![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/lumacode/IMG_0330.jpg)

Once lumacode is enabled, you will see what looks like a gray scale image.  This is the luma code encoding.  In this mode, only the first four luma levels are used.  Phase and amplitude and color burst values are not relevant.

![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/lumacode/IMG_0331.jpg)

Now power off your machine and start working on the connections.

# Kawari Side Connection

The challenge for the connections on the Kawari side is that there is no Vic-II-Dizer to easily tap into the Luma, 5V and GND pins. So we must improvise.

The luma signal from the Kawari's luma pin (15) must be diverted away from the motherboard's socket. Also, before passing the signal on to its destination (the RF modulator's RCA jack or directly to the analog board), the luma line is first pulled up to 5V through a 120 ohm resistor, then tied to GND through a 75 ohm resistor. 

IMPORTANT: The luma signal no longer enters the motherboard's socket. Therefore, the regular video out jack at the rear of the machine will no longer carry a video signal.

One way to prepare the Kawari side connection is to use an extra machined pin socket that will sit between the Kawari and the motherboard. This extra socket will take the place of the VIC-II-dizer. Bend pin 15 up so it won't touch the motherboard socket's pin 15 location.  I used [AR-40-HZL-TT](https://www.digikey.ca/en/products/detail/assmann-wsw-components/AR-40-HZL-TT/821772) from DigiKey. Then I pulled out three jumper header pins from an old connector and soldered them to +5V, GND and Luma pins, making sure the solder joints did not interfere with the insertion of the socket.  There is plenty of room on the base of the pin to attach the headers.  Make sure the luma pin does won't contact with the socket below it.  (I can't guarantee the solder joints will hold with wear and tear but this was only an experiment.)

![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/lumacode/IMG_0306.jpg)
![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/lumacode/IMG_0304.jpg)
![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/lumacode/IMG_0305.jpg)

This is what it should look like from the top:

![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/lumacode/IMG_0307.jpg)

You will need a section of a 2-wire cable you can strip at both ends.  I found an old RCA video cable but you could use two separate wires as is shown in the official Vic-ii-dizer [HOWTO Page](https://github.com/c0pperdragon/LumaCode/wiki/VIC-II-dizer-\(for-the-C64-computer\)#mod-kit-contents).  The wire needs to be long enough to reach either the analog board's 6pin input connector directly or the RF modulator's RCA jack from the VIC-II socket. 

You will also need a 120 ohm resistor and a 75 ohm resistor.


Take the 120ohm and 75ohm resistors and wrap two legs together. 

![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/lumacode/IMG_0310.jpg)

Now take 3 female jumper wires and strip one end; Red for +5V, Green for GND, and Orange for Luma (see pic below). These will plug into the header pins you soldered to the socket.  Make sure the 5V (red) wire is a little longer as it has to travel a longer distance to the cable.

![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/lumacode/IMG_0314.jpg)

Now solder the two wrapped legs, the 'signal' wire from your two wire cable and the end of the Orange (Luma) connetor wire together. Solder the free end of the 120ohm resistor to the Red (5V) jumper wire and the free end of the 75 ohm resistor to GND.  The other wire from your 2-wire cable will carry GND which should also connect to the green GND wire.  My wire was short so I added a short white wire to make the jump.

Here is what the connections will look like (before soldering):

![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/lumacode/IMG_0315.jpg)

After soldering and adding some heat shrink tubin to protect from shorts, this is what things should look like:

![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/lumacode/IMG_0320.jpg)

    Plug the Red wire into the socket's header pin 40 (+5V)
    Plug the Green wire into the socket's header pin 20 (GND)
    Plug the Orange wire into the socket's header pin 15 (LUMA)

![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/lumacode/IMG_0323.jpg)

Now plug the Kawari into the socket.  Here is what it looks like from above:

![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/lumacode/IMG_0325.jpg)

# RGB2HDMI Side Connection

That takes care of the Kawari side connection.  The analog board connection can either go directly to the analog board or you can connect the GND and LUMA wires to the RF modulator as described by the VIC-II-dizer mod link above.  In my case, I went straight to the analog board.  If you chose to use the RF modulator's RCA jack, you will then need to build or buy your own RCA ![LumaCode Cable For RGB2HDMI](https://www.tindie.com/products/c0pperdragon/lumacode-cable-for-rgbtohdmi/).  However, this cable pretty much the same as what is described here except the other end of the cable is an RCA connector.

On the other end of your cable, attach three more female jumpers. These will plug directly into the analog board's 6-pin connector.  The two orange jumpers are split from the luma 'signal' wire.  The remaining GND wire is black in this picture:

![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/lumacode/IMG_0325.jpg)

With the RGB2HDMI board's buttons on the top side, the black (GND) wire will plug into the bottom left most pin on the 6-pin header.  The two orange (LUMA) wires will plug into the top left two pins as shown here:

![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/lumacode/IMG_0317.jpg)

And another view:

![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/lumacode/IMG_0319.jpg)

# Analog Board Configuration

Set your RGB2HDMI profile to Commodore -> Commodore 64 Lumacode
Then bring up the sampling menu.
The configuration is as follows:

    Setup Mode: Normal
    Sampling Phase: 3 (180 Degrees)
    Half Pixel shift: Off
    Clock Multiplier: x6
    Calibration Range: Auto
    Pixel H Offset: 6
    Sync Edge: Trailing
    Sync on G/V: Off
    Sample Mode: 6 Bits (4 levels)
    75R Termination: Off <- NOTE this is different than Vic-II dizer
    DAC-A: G Hi : 138 (1.79v)
    DAC-B: G Lo : 119 (1.54v)
    DAC-C: RB Hi : Disabled
    DAC-D: RB Lo : Disabled
    DAC-E: Sync : 067 (0.87v)
    DAC-F: G Mid : 129 (1.67v)
    DAC-G: R Mid : Disabled
    DAC-H: B Mid : Disabled

IMPORTANT: There are TWO 'profiles' for Lumacode saved by the RGB2HDMI board. One for 50hz Sync and another for 60hz Sync. You must set BOTH profiles and save them.  I *think* the board simply detects which one based on what frequency it syncs to and then when you save your configuration, that's the one it saves to.  So be aware that you may have to adjust all the settings AGAIN for the other frequency if you switchy your Kawari between 50 and 60 hz modes.  Also, as mentioned above, you need to enable LumaCode in COMPED for all chipsets.

NOTE: The voltage levels and some other configuration parameters will be different than that of a VIC-II-dizer configuration.  If you need to change 75 ohm termination to 'off' from your existing configuration, I suggest saving the configuration and then COLD booting your Pi (not just a reset).  I noticed several times that despite turning off 75 ohm termination, the signal would never clear up but if I cold booted after changing this setting, I was able to get a solid picture.

NOTE: It may be possible to simply omit the 75ohm -> GND wire in these instructions and instead use the analog board's on-board 75ohm termination.  This _should_ work, however, I was not able to get as clear a picture.

Now plug the Kawari, the extra socket into the VIC-II socket of your motherboard. 

![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/lumacode/IMG_0326.jpg)

Now boot and you should see a stable HDMI image from your Pi's HDMI port.  The green light on your RGB2HDMI board may flash for a bit while it attempts to detect sync.

![alt text](https://raw.githubusercontent.com/randyrossi/vicii-kawari/main/doc/images/lumacode/IMG_0327.jpg)

# Adjusting the voltage levels

With the Kawari, you can adjust both the voltage comparitor ranges on the RGB2HDMI board AND/OR the luma levels in COMPED.  The default values for luma levels 0, 1, 2 & 3 should be sufficient.  However, if you notice some 'sparkling' artifacts, it is worth trying the COMPED program to adjust levels 0, 1 & 2 to see if you can eliminate them.  I don't recommend adjusting level 3 because the voltage 'difference' is quite large (the luma levels adjustments from COMPED are not linear).

# Fallback to older firmware

If your fallback firmware is below 1.17, when it boots, the luma levels will be too close together to make any text out.  You will either have to blind load COMPED.PRG and press 'J' then hit return, or short the Kawari's config reset jumpers to get a working display again.

Good Luck!
