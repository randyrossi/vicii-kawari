echo "Spartan Large - Beta"

echo "   Multiboot"
cp hex/multi/spartan/kawari_multiboot_MAIN_1.15.bit .
DISKNUMS="1 2 3 4" NAME=kawari VERSION=1.15 FPGA=spartan6_x16 START_ADDRESS=512000 IMAGE_SIZE=512000 TYPE=multiboot VARIANT=MAIN PAGE_SIZE=16384 NUM_DISKS=4 make -f Makefile clean zip

echo "   Golden"
cp hex/multi/spartan/kawari_golden_MAIN_1.14.bit .
DISKNUMS="1 2 3 4" NAME=kawari VERSION=1.14 FPGA=spartan6_x16 START_ADDRESS=0 IMAGE_SIZE=512000 TYPE=golden VARIANT=MAIN PAGE_SIZE=16384 NUM_DISKS=4 make -f Makefile clean zip

echo "Spartan Large - Final"

echo "   Multiboot"
cp hex/multi/spartan/kawari_multiboot_MAINLD_1.15.bit .
DISKNUMS="1 2 3 4" NAME=kawari VERSION=1.15 FPGA=spartan6_x16 START_ADDRESS=512000 IMAGE_SIZE=512000 TYPE=multiboot VARIANT=MAINLD PAGE_SIZE=16384 NUM_DISKS=4 make -f Makefile clean zip

echo "   Golden"
cp hex/multi/spartan/kawari_golden_MAINLD_1.14.bit .
DISKNUMS="1 2 3 4" NAME=kawari VERSION=1.14 FPGA=spartan6_x16 START_ADDRESS=0 IMAGE_SIZE=512000 TYPE=golden VARIANT=MAINLD PAGE_SIZE=16384 NUM_DISKS=4 make -f Makefile clean zip

