VIC-II Kawari Demo Disk

NOTE: cc65.patch must be applied to cc65 build or this demo will not compile/run
      ALSO the util module must be compiled with the same hacked cc65 (anything we link to)

Memory:

0x0801 Initial PRG
0x0f82 MUSIC HDR
0x1000 MUSIC (max 8k)
0x3000 custom char or color data
0x40A0 CC65 PROG START ADDR

Every segment can load into 0x40a0 while music is playing.
Need to skip past header so actual code starts at 40a9
The space between 31e8 and 40a0 is used by cc65 but not entirely sure how.
So music can't go too far 31e8 or the data will be overwritten by cc65 compiled segments.

The space from 0x801 - 0x80c can be reclaimed for temp space by segments
since it held the start basic code which is never used again.
