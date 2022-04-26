# Spartan6

    Use build.sh in rev_4H or rev_4S dirs.
    Will produce two build .bit files. One for active (multiboot) and another for fallback (golden)
    Set Makefile params at top to build flash image for what you want.

# Efinix
    Build multi.hex using programmer's 'combine multiple images' option

## Direct SPI Programming
    openFPGALoader -b xyloni_spi -c digilent_ad /home/rrossi/multi.hex  --verify

## Making a Flash Disk

    multi_hex_to_bin multi.hex > kawari_multiboot_LH_1.1.bit
