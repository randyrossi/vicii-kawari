#!/bin/sh

mkdir -p build

make -f Makefile clean golden > build/rev_3.golden.log
make -f Makefile clean multiboot > build/rev_3.multiboot.log
make -f Makefile mcs
