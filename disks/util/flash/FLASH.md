# Spartan6

    Use build.sh in rev_4H or rev_4S dirs.
    Will produce two build .bit files. One for active (multiboot) and another for fallback (golden)
    Set Makefile params at top to build flash image for what you want.

## Large

    FPGA=spartan6_x16
    START_ADDRESS=512000
    TYPE=multiboot
    REG_VARIANT=MAINLD
    BUILD_VARIANT=LD
    PAGE_SIZE=16384

# Efinix

    Build multi.hex using programmer's 'combine multiple images' option

## Large (tbd)

    FPGA=efinix_t20
    START_ADDRESS=659456
    TYPE=multiboot
    REG_VARIANT=MAINLG
    BUILD_VARIANT=LG
    PAGE_SIZE=16384

## Mini (board rev 1.3)

    FPGA=efinix_t20
    START_ADDRESS=659456
    TYPE=multiboot
    REG_VARIANT=MAINLH
    BUILD_VARIANT=LH
    PAGE_SIZE=16384

## POV (board rev 1.3)

    FPGA=efinix_t8
    START_ADDRESS=659456
    TYPE=multiboot
    REG_VARIANT=MAINLI
    BUILD_VARIANT=LI
    PAGE_SIZE=4096


## Direct SPI Programming

    openFPGALoader -b xyloni_spi -c digilent_ad /home/rrossi/multi.hex  --verify

## Making a Flash Disk

    multi_hex_to_bin multi.hex > kawari_multiboot_LH_1.1.bit
