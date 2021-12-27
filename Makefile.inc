all: program

# This is the build that gets booted unless there's
# a fallback situation.
MULTIBOOT_MAJOR=0
MULTIBOOT_MINOR=8

# This is the golden master stable fallback image.
GOLDEN_MAJOR=0
GOLDEN_MINOR=7

# Use this makefile to create a multiboot image.
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

install_config:
	cp ${BOARD_REV}${VARIANT}.config.vh ../hdl/config.vh
	java -cp ../hdl GenConstraints ../hdl/config.vh ../hdl/${BOARD_REV}/wiring.txt > ../hdl/${BOARD_REV}/top.ucf

compile:
	mkdir -p xst/projnav.tmp
	xst -intstyle ise -ifn "../kawari.xst" -ofn "top.syr"
	ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc ../hdl/${BOARD_REV}/top.ucf -p ${FPGA} top.ngc top.ngd
	map -intstyle ise -p ${FPGA} -w -logic_opt off -ol high -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -mt off -detail -ir off -pr off -lc off -power off -o top_map.ncd top.ngd top.pcf
	par -w -intstyle ise -ol high -xe c -mt 4 top_map.ncd top.ncd top.pcf

golden_version:
	perl -pi.bak -e "s/VERSION_MAJOR.*/VERSION_MAJOR 8'd${GOLDEN_MAJOR}/g" ../hdl/config.vh
	perl -pi.bak -e "s/VERSION_MINOR.*/VERSION_MINOR 8'd${GOLDEN_MINOR}/g" ../hdl/config.vh

multiboot_version:
	perl -pi.bak -e "s/VERSION_MAJOR.*/VERSION_MAJOR 8'd${MULTIBOOT_MAJOR}/g" ../hdl/config.vh
	perl -pi.bak -e "s/VERSION_MINOR.*/VERSION_MINOR 8'd${MULTIBOOT_MINOR}/g" ../hdl/config.vh

golden: install_config golden_version compile
	mkdir -p build
	bitgen -intstyle ise -f ../kawari_golden.ut top.ncd
	mv top.bit build/kawari_golden_${BOARD_REV}${VARIANT}_${GOLDEN_MAJOR}.${GOLDEN_MINOR}.bit

multiboot: install_config multiboot_version compile
	mkdir -p build
	bitgen -intstyle ise -f ../kawari_multiboot.ut top.ncd
	mv top.bit build/kawari_multiboot_${BOARD_REV}${VARIANT}_${MULTIBOOT_MAJOR}.${MULTIBOOT_MINOR}.bit

mcs:
	mkdir -p build
	promgen -w -p mcs -c FF -o build/spix4_MultiBoot_${BOARD_REV}${VARIANT}_${GOLDEN_MAJOR}_${GOLDEN_MINOR}-${MULTIBOOT_MAJOR}_${MULTIBOOT_MINOR} -s 2048 -u 0000 build/kawari_golden_${BOARD_REV}${VARIANT}_${GOLDEN_MAJOR}.${GOLDEN_MINOR}.bit -u 07d000 build/kawari_multiboot_${BOARD_REV}${VARIANT}_${MULTIBOOT_MAJOR}.${MULTIBOOT_MINOR}.bit -spi

program:
	cat ../kawari_progspi.cmd | sed "s/%BOARD_REV%/${BOARD_REV}/g" | sed "s/%VARIANT%/${VARIANT}/g" | sed "s/%GOLDEN_MAJOR%/${GOLDEN_MAJOR}/g" | sed "s/%GOLDEN_MINOR%/${GOLDEN_MINOR}/g" | sed "s/%MULTIBOOT_MAJOR%/${MULTIBOOT_MAJOR}/g" | sed "s/%MULTIBOOT_MINOR%/${MULTIBOOT_MINOR}/g" > kawari_progspi.tmp
	impact -batch kawari_progspi.tmp

clean:
	rm -rf 	output.txt
	rm -rf 	'C:\nppdf32Log\debuglog.txt'
	rm -rf  _impactbatch.log
	rm -rf  kawari_progspi.tmp
	rm -rf 	_ngo/
	rm -rf 	iseconfig/top.xreport
	rm -rf 	par_usage_statistics.html
	rm -rf 	rev_3.gise
	rm -rf 	top.bgn
	rm -rf 	top.bin
	rm -rf 	top.bld
	rm -rf 	top.cmd_log
	rm -rf 	top.drc
	rm -rf 	top.lso
	rm -rf 	top.ncd
	rm -rf 	top.ngc
	rm -rf 	top.ngd
	rm -rf 	top.ngr
	rm -rf 	top.pad
	rm -rf 	top.par
	rm -rf 	top.pcf
	rm -rf 	top.ptwx
	rm -rf 	top.stx
	rm -rf 	top.syr
	rm -rf 	top.twr
	rm -rf 	top.twx
	rm -rf 	top.unroutes
	rm -rf 	top.ut
	rm -rf 	top.xpi
	rm -rf 	top.xst
	rm -rf 	top_*.twx
	rm -rf 	top_bitgen.xwbt
	rm -rf 	top_envsettings.html
	rm -rf 	top_guide.ncd
	rm -rf 	top_map.map
	rm -rf 	top_map.mrp
	rm -rf 	top_map.ncd
	rm -rf 	top_map.ngm
	rm -rf 	top_map.xrpt
	rm -rf 	top_ngdbuild.xrpt
	rm -rf 	top_pad.csv
	rm -rf 	top_pad.txt
	rm -rf 	top_par.xrpt
	rm -rf 	top_summary.html
	rm -rf 	top_summary.xml
	rm -rf 	top_usage.xml
	rm -rf 	top_xst.xrpt
	rm -rf 	webtalk.log
	rm -rf 	webtalk_pn.xml
	rm -rf 	xlnx_auto_0_xdb/
	rm -rf 	xst/
	rm -rf _xmsgs
