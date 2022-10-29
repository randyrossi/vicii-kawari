# A program to activate 80 column mode on the VIC-II Kawari

Note this requires 2X native to be enabled.  1X native will skip
every other pixel. Check your config.

    SYS 51200 = activate

    SYS 51203 = toggle between 40 and 80 columns

NOTE: The 80 column mode uses the A and B VMEM pointers and indices. If you intend to use those in your program while 80 column mode is enabled, you will need to save/restore those registers before/after you use them to avoid collision with the print routines.
