#!/bin/sh

mkdir -p build

#cp rev_4SA.top.prj top.prj
#make -f rev_4SA.Makefile clean golden > build/rev_4SA.golden.log
#make -f rev_4SA.Makefile clean multiboot > build/rev_4SA.multiboot.log
#make -f rev_4SA.Makefile mcs

#cp rev_4SAO.top.prj top.prj
#make -f rev_4SAO.Makefile clean golden > build/rev_4SAO.golden.log
#make -f rev_4SAO.Makefile clean multiboot > build/rev_4SAO.multiboot.log
#make -f rev_4SAO.Makefile mcs

cp rev_4SB.top.prj top.prj
make -f rev_4SB.Makefile clean golden > build/rev_4SB.golden.log
make -f rev_4SB.Makefile clean multiboot > build/rev_4SB.multiboot.log
make -f rev_4SB.Makefile mcs

cp rev_4SBO.top.prj top.prj
make -f rev_4SBO.Makefile clean golden > build/rev_4SBO.golden.log
make -f rev_4SBO.Makefile clean multiboot > build/rev_4SBO.multiboot.log
make -f rev_4SBO.Makefile mcs
