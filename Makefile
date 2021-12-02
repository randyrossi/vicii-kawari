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
# 	top.prj
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
	rm -rf op.stx top_summary.html top.xst top.lso top.syr top_xst.xrpt
	rm -rf webtalk_pn.xml top.ngc top.ngr xst top.cmd_log xst.xmsgs top.ngd
	rm -rf top.bld top_ngdbuild.xrpt _ngo xlnx_auto_0_xdb ngdbuild.xmsgs top_map.map
	rm -rf top_map.mrp top_map.xrpt top_map.ncd top.pcf top_map.ngm top_usage.xml
	rm -rf top_summary.xml map.xmsgs top.ncd top.pad top.par top.unroutes
	rm -rf top.xpi top_par.xrpt top_pad.txt top_pad.csv top.ptwx par.xmsgs
	rm -rf top.twr top.twx trce.xmsgs top.drc top.bit top.bgn top.bin top.ut
	rm -rf webtalk.log bitgen.xmsgs top*.twx kawari_progspi.tmp _xmsgs iseconfig/top.xreport
	rm -rf tmp _xmsgs iseconfig/top.xreport

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

