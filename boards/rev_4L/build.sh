#!/bin/sh

mkdir -p build

VARIANT=MAIN make clean golden > build/LD.golden.log
VARIANT=MAIN make clean multiboot > build/LD.multiboot.log
VARIANT=MAIN make mcs
