#!/bin/sh

mkdir -p build

# Full image for programmer
#VARIANT=MAINLD make clean golden > build/LD.golden.MAIN.log
#VARIANT=MAINLD make clean multiboot > build/LD.multiboot.MAIN.log
#VARIANT=MAINLD make mcs

# Just for flash disks...
VARIANT=MAINLD make clean multiboot > build/LD.multiboot.MAIN.log
