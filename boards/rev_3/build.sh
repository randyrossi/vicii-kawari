#!/bin/sh

mkdir -p build

# Full image for programmer
#VARIANT=MAIN make clean golden > build/rev_3T.MAIN.golden.log
#VARIANT=MAIN make clean multiboot > build/rev_3T.MAIN.multiboot.log
#VARIANT=MAIN make mcs

# Just for flash disks...
VARIANT=MAIN make clean multiboot > build/rev_3T.MAIN.multiboot.log
VARIANT=MKII make clean multiboot > build/rev_3T.MKII.multiboot.log
VARIANT=SARU make clean multiboot > build/rev_3T.SARU.multiboot.log
