# Efinix Trion project files

IMPORTANT: Make sure bistream generation has SPI 4X
selected in the project's settings.  Otherwise, the
bitstream will not load since the FPGA is configured
for 4X SPI.

# Making a Bistream

Make a bitstream multi.hex with the images in slots 00 and 10 (0 & 2)
Active is 2.  Fallback is 0 (triggered by grounding a TP on the board)

# SPI Programming

    CRESET must be connected to GND for programming

    openFPGALoader -b xyloni_spi -c digilent_ad multi.hex --verify

    (Example using Xilinx programmer)

# Making a flash disk (.d64 or .d81)

Generate a multi.hex file bitstream as descibed above
and then use the util/flash directory to convert it to a .bit file
for the Makefile to generate disks from.
