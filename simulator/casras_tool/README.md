This is a tool to help set the values/logic the dot4x and col16x signals Kawari combines to create the CAS/RAS rise/fall times.

The original logic attempted to make CAS/RAS rise/fall solely off the dot4x clock but the resolution was too low. Even using the negative edge of the dot4x clock wasn't enough.  So we use the 16x color clock to get some finer control on the rising/falling edges by OR'ing some signals together.

See ../../hdl/CAS_RAS_CLOCKS.txt for some more info.

The program wave.c can output different versions of the logic. So far, it has v17 or lower and v18 which is the point at which
we fixed the CAS rise problem causing glitches on some Saruman modules.

