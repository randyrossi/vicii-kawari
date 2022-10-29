The Efinix Trion FPGAs do not support TMDS.
So we encode the DVI protocol over LVDS and
convert to CML using 
It's possible to A/C couple the LVDS lines
to the DVI/HDMI connector pins using a
100nf capacitor.  But this limits the dot
clock to (probably) around 25Mhz.
Unfortunately, we need around 32Mhz.
