#!/bin/sh

mkdir -p build

# Full image for programmer
#VARIANT=MAIN make clean golden > build/LD.golden.MAIN.log
#VARIANT=MAIN make clean multiboot > build/LD.multiboot.MAIN.log
#VARIANT=MAIN make mcs

# Just for flash disks...
VARIANT=MAINLD make clean multiboot > build/LD.multiboot.MAIN.log
VARIANT=SARULD make clean multiboot > build/LD.multiboot.SARU.log
