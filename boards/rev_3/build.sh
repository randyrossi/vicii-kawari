#!/bin/sh

mkdir -p build

VARIANT=MAIN make clean golden > build/rev_3T.MAIN.golden.log
VARIANT=MAIN make clean multiboot > build/rev_3T.MAIN.multiboot.log
VARIANT=MAIN make mcs
