all: program

# This is the build that gets booted unless there's
# a fallback situation.
MULTIBOOT_MAJOR=0
MULTIBOOT_MINOR=2

# This is the golden master stable fallback image.
GOLDEN_MAJOR=0
GOLDEN_MINOR=1

# Use this makefile to create a multiboot image.
# Golden version is set to 0.1
# Multiboot version is set to 1.0
#
# Usage:
#	make clean golden
#	make clean multiboot
#	make mcs
#	make program
#
# Required files:
# 	kawari.xst
# 	kawari_golden.ut
# 	kawari_multiboot.ut
# 	kawari_progspi.cmd
# 	top.prj <- Get this from ISE gen dir for same config
#
# Outputs:
#       build/kawari_multiboot_MAJOR_MINOR.bit
#       build/kawari_golden_MAJOR_MINOR.bit
#       build/spix4_MultiBoot_GOMJ_GOMI-MBMJ_MBMI.mcs
#
# The flash builder utility expects the kawari_multiboot_MAJOR_MINOR.bit
# file to create flash disks. Only the multiboot image is ever replaced
# on a device.

clean:
	rm -rf tmp _xmsgs
	rm -rf rev_3/iseconfig/top.xreport
	rm -rf rev_3/par_usage_statistics.html
	rm -rf rev_3/top_bitgen.xwbt
	rm -rf rev_3/top_guide.ncd
	rm -rf rev_3/top_summary.html
	rm -rf rev_4L/iseconfig/top.xreport
	rm -rf rev_4L/par_usage_statistics.html
	rm -rf rev_4L/top_bitgen.xwbt
	rm -rf rev_4L/top_guide.ncd
	rm -rf rev_4L/top_summary.html
	rm -rf rev_4S/iseconfig/top.xreport
	rm -rf rev_4S/par_usage_statistics.html
	rm -rf rev_4S/top_bitgen.xwbt
	rm -rf rev_4S/top_guide.ncd
	rm -rf rev_4S/top_summary.html
	rm -rf top_summary.html

compile:
	mkdir -p xst/projnav.tmp
	xst -intstyle ise -ifn "kawari.xst" -ofn "top.syr"
	ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc hdl/rev_3/top.ucf -p xc6slx16-ftg256-2 top.ngc top.ngd
	map -intstyle ise -p xc6slx16-ftg256-2 -w -logic_opt off -ol high -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -mt off -detail -ir off -pr off -lc off -power off -o top_map.ncd top.ngd top.pcf
	par -w -intstyle ise -ol high -xe c -mt 4 top_map.ncd top.ncd top.pcf

golden_version:
	perl -pi.bak -e "s/VERSION_MAJOR.*/VERSION_MAJOR 8'd${GOLDEN_MAJOR}/g" hdl/config.vh
	perl -pi.bak -e "s/VERSION_MINOR.*/VERSION_MINOR 8'd${GOLDEN_MINOR}/g" hdl/config.vh

multiboot_version:
	perl -pi.bak -e "s/VERSION_MAJOR.*/VERSION_MAJOR 8'd${MULTIBOOT_MAJOR}/g" hdl/config.vh
	perl -pi.bak -e "s/VERSION_MINOR.*/VERSION_MINOR 8'd${MULTIBOOT_MINOR}/g" hdl/config.vh

golden: clean golden_version compile
	mkdir -p build
	bitgen -intstyle ise -f kawari_golden.ut top.ncd
	mv top.bit build/kawari_golden_${GOLDEN_MAJOR}.${GOLDEN_MINOR}.bit

multiboot: clean multiboot_version compile
	mkdir -p build
	bitgen -intstyle ise -f kawari_multiboot.ut top.ncd
	mv top.bit build/kawari_multiboot_${MULTIBOOT_MAJOR}.${MULTIBOOT_MINOR}.bit

mcs:
	mkdir -p build
	promgen -w -p mcs -c FF -o build/spix4_MultiBoot_${GOLDEN_MAJOR}_${GOLDEN_MINOR}-${MULTIBOOT_MAJOR}_${MULTIBOOT_MINOR} -s 2048 -u 0000 build/kawari_golden_${GOLDEN_MAJOR}.${GOLDEN_MINOR}.bit -u 07d000 build/kawari_multiboot_${MULTIBOOT_MAJOR}.${MULTIBOOT_MINOR}.bit -spi

program:
	cat kawari_progspi.cmd | sed "s/%GOLDEN_MAJOR%/${GOLDEN_MAJOR}/g" | sed "s/%GOLDEN_MINOR%/${GOLDEN_MINOR}/g" | sed "s/%MULTIBOOT_MAJOR%/${MULTIBOOT_MAJOR}/g" | sed "s/%MULTIBOOT_MINOR%/${MULTIBOOT_MINOR}/g" > kawari_progspi.tmp
	impact -batch kawari_progspi.tmp

