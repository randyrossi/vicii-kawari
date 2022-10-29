#!/bin/sh

mkdir -p build

VARIANT=MAIN make clean golden > build/LD.golden.MAIN.log
VARIANT=MAIN make clean multiboot > build/LD.multiboot.MAIN.log
VARIANT=MAIN make mcs
