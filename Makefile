all: program

# Use this makefile to create a multiboot image.
# Golden version is set to 0.15
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
# For rev_2 boards with no lock bits, remember to set
# cfg pins to pullup/pulldown to unlock functions.
# Simulate jumper removed from cfg1/spi_lock
# Simulate jumpers in place for cfg2/extensions_lock
#          and cfg3/persistence_lock
#
# NET "cfg1" LOC=P57;
# NET "cfg1" PULLUP;
# NET "cfg2" LOC=P58;
# NET "cfg2" PULLDOWN;
# NET "cfg3" LOC=P59;
# NET "cfg3" PULLDOWN;

clean:
	rm -rf op.stx top_summary.html top.xst top.lso top.syr top_xst.xrpt
	rm -rf webtalk_pn.xml top.ngc top.ngr xst top.cmd_log xst.xmsgs top.ngd
	rm -rf top.bld top_ngdbuild.xrpt _ngo xlnx_auto_0_xdb ngdbuild.xmsgs top_map.map
	rm -rf top_map.mrp top_map.xrpt top_map.ncd top.pcf top_map.ngm top_usage.xml
	rm -rf top_summary.xml map.xmsgs top.ncd top.pad top.par top.unroutes
	rm -rf top.xpi top_par.xrpt top_pad.txt top_pad.csv top.ptwx par.xmsgs
	rm -rf top.twr top.twx trce.xmsgs top.drc top.bit top.bgn top.bin top.ut
	rm -rf webtalk.log bitgen.xmsgs top*.twx

compile:
	mkdir -p xst/projnav.tmp
	xst -intstyle ise -ifn "kawari.xst" -ofn "top.syr"
	ngdbuild -intstyle ise -dd _ngo -nt timestamp -uc hdl/rev_2/top.ucf -p xc6slx9-tqg144-2 top.ngc top.ngd
	map -intstyle ise -p xc6slx9-tqg144-2 -w -logic_opt off -ol high -t 1 -xt 0 -register_duplication off -r 4 -global_opt off -mt off -detail -ir off -pr off -lc off -power off -o top_map.ncd top.ngd top.pcf
	par -w -intstyle ise -ol high -xe c -mt 4 top_map.ncd top.ncd top.pcf

golden_version:
	perl -pi.bak -e "s/VERSION_MAJOR.*/VERSION_MAJOR 4'd0/g" hdl/config.vh
	perl -pi.bak -e "s/VERSION_MINOR.*/VERSION_MINOR 4'd15/g" hdl/config.vh

multiboot_version:
	perl -pi.bak -e "s/VERSION_MAJOR.*/VERSION_MAJOR 4'd1/g" hdl/config.vh
	perl -pi.bak -e "s/VERSION_MINOR.*/VERSION_MINOR 4'd0/g" hdl/config.vh

golden: clean golden_version compile
	bitgen -intstyle ise -f kawari_golden.ut top.ncd
	mv top.bit kawari_golden.bit

multiboot: clean multiboot_version compile
	bitgen -intstyle ise -f kawari_multiboot.ut top.ncd
	mv top.bit kawari_multiboot.bit

mcs:
	promgen -w -p mcs -c FF -o spix4_MultiBoot -s 2048 -u 0000 kawari_golden.bit -u 07d000 kawari_multiboot.bit -spi

program:
	impact -batch kawari_progspi.cmd
