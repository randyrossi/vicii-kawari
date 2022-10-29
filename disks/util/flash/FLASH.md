# Spartan6

    Use build.sh in rev_4H or rev_4S dirs.
    Will produce two build .bit files. One for active (multiboot) and another for fallback (golden)
    Set Makefile params at top to build flash image for what you want.

## Large

golden             | multiboot
-------------------|---------------------
FPGA=spartan6_x16  | FPGA=spartan6_x16
START_ADDRESS=0    | START_ADDRESS=512000
IMAGE_SIZE=512000  | IMAGE_SIZE=512000   
TYPE=golden        | TYPE=multiboot
REG_VARIANT=MAINLD | REG_VARIANT=MAINLD
BUILD_VARIANT=LD   | BUILD_VARIANT=LD
PAGE_SIZE=16384    | PAGE_SIZE=16384

# Efinix

    Build multi.hex using programmer's 'combine multiple images' option

## Large (tbd)

golden             | multiboot
-------------------|---------------------
FPGA=efinix_t20    | FPGA=efinix_t20
START_ADDRESS=0    | START_ADDRESS=659456
IMAGE_SIZE=659465  | IMAGE_SIZE=659456
TYPE=golden        | TYPE=multiboot
REG_VARIANT=MAINLG | REG_VARIANT=MAINLG
BUILD_VARIANT=LG   | BUILD_VARIANT=LG
PAGE_SIZE=4096     | PAGE_SIZE=4096

## Mini (board rev 1.3)

golden             | multiboot
-------------------|---------------------
FPGA=efinix_t20    | FPGA=efinix_t20
START_ADDRESS=0    | START_ADDRESS=659456
IMAGE_SIZE=659465  | IMAGE_SIZE=659456
TYPE=golden        | TYPE=multiboot
REG_VARIANT=MAINLH | REG_VARIANT=MAINLH
BUILD_VARIANT=LH   | BUILD_VARIANT=LH
PAGE_SIZE=4096     | PAGE_SIZE=4096 

## POV (board rev 1.3)

golden             | multiboot
-------------------|---------------------
FPGA=efinix_t8     | FPGA=efinix_t8
START_ADDRESS=0    | START_ADDRESS=659456
IMAGE_SIZE=659465  | IMAGE_SIZE=659456
TYPE=golden        | TYPE=multiboot
REG_VARIANT=MAINLF | REG_VARIANT=MAINLF
BUILD_VARIANT=LF   | BUILD_VARIANT=LF
PAGE_SIZE=4096     | PAGE_SIZE=4096

## Direct SPI Programming

This will program both multiboot and golden images directly to the flash via SPI.

    openFPGALoader -b xyloni_spi -c digilent_ad /home/rrossi/multi.hex  --verify

## Making a Flash Disk

Before making a flash disk, you must create the bit files using the utility script for efinix devices.

    ./efinix_prep.sh multi.hex golden 1.4 
    ./efinix_prep.sh multi.hex multiboot 1.5 
