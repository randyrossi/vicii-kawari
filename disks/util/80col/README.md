# A program to activate 80 column mode on the VIC-II Kawari

Note this requires 2X native to be enabled.  1X native will skip
every other pixel. Check your config.

    SYS 51200 = activate

    SYS 51203 = toggle between 40 and 80 columns

NOTE: The 80 column mode uses the A and B VMEM pointers and indices. If you intend to use those in your program while 80 column mode is enabled, you will need to save/restore those registers before/after you use them to avoid collision with the print routines.

# 80col-header.basic

A header for a basic program that will enable 80 columns without destroying the basic program in memory. Installs a small loader program into the casette buffer and modifies the 80 column wedge to return rather than calling basic cold start.

# 80col-jiffy.asm

This is an alternate version of the 80 column wedge that seems
to be more compatible with JiffyDos. JiffyDos makes some
assumptions about where the screen memory is and fiddles with
the screen pointer values at d1/d2 outside of the calls to
the kernel. This causes the regular wedge to go off the rails
on a scroll and it causes corruption on the return back to
kernal code. This version moves screen memory to 0x0000 in
kawari memory space. It's not a perfect solution since commands
like @ sometimes prints the results at random locations on
the screen but at least the d1/d2 values remain within valid
matrix memory and avoids the issue. To use this, just compile
instead of 80col-51200 and activate it the same way as the
default wedge.

