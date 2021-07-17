Use CMOD-A7 as test harness. Can't hook up to a real C64 bus easily
with all video options as there aren't enough pins.  But can be
used to gen a video image with the test pattern or verify EEPROM
communication is working.  NOTE: We lie and say we have color clocks
because we generate one from the 12mhz on board clock.  It is accurate
enough for NTSC but slightly off for PAL.  But it will still generate
a useful image.

Use this in config.vh

`define CMOD_BOARD 1
`define TEST_PATTERN 1
`define GEN_LUMA_CHROMA 1
`define HAVE_EEPROM 1
`define HIRES_MODES
