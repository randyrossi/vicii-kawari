#!/bin/bash

VER=1.19

# Golden points to fallback at 0a6000 for LG and 0a1000 for LH builds
# Active points to nothing 000000
# $1 = filename
# $2 = octal row position to find the pointer
show_start_bytes()
{
   echo -n "$1 Golden = "
   od -t x1 ${1} | grep 0000500 | sed 's/^0000500 .. .. .. .. .. .. .. .. //' | sed 's/.. .. .. .. ..$//' | tr -d '\n'
   echo
   echo -n "$1 Active = "
   od -t x1 ${1} | grep ${2} | sed "s/^${2} .. .. .. .. .. .. .. .. //" | sed 's/.. .. .. .. ..$//' | tr -d '\n'
   echo
}

ls -l hex/multi/${VER}/kawari_${VER}_${VER}_multi_LG_DVI-29MHZ-U.hex
ls -l hex/multi/${VER}/kawari_${VER}_${VER}_multi_LG_DVI-27MHZ-S.hex
ls -l hex/multi/${VER}/kawari_${VER}_${VER}_multi_LG_RGB-32MHZ-U.hex
ls -l hex/multi/${VER}/kawari_${VER}_${VER}_multi_LH.hex
ls -l hex/multi/${VER}/kawari_${VER}_${VER}_multi_LH-DOTC-1.2.hex
ls -l hex/multi/${VER}/kawari_${VER}_${VER}_multi_LH-DOTC-1.5.hex

echo "=================="
echo "Check source files"
echo "=================="
read n
echo

mkdir -p tmp/bit/${VER}

./multi_hex_to_bit hex/multi/${VER}/kawari_${VER}_${VER}_multi_LG_DVI-29MHZ-U.hex tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LG_DVI-29MHZ-U.bit
./multi_hex_to_bit hex/multi/${VER}/kawari_${VER}_${VER}_multi_LG_DVI-27MHZ-S.hex tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LG_DVI-27MHZ-S.bit
./multi_hex_to_bit hex/multi/${VER}/kawari_${VER}_${VER}_multi_LG_RGB-32MHZ-U.hex tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LG_RGB-32MHZ-U.bit
./multi_hex_to_bit hex/multi/${VER}/kawari_${VER}_${VER}_multi_LH.hex tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LH.bit
./multi_hex_to_bit hex/multi/${VER}/kawari_${VER}_${VER}_multi_LH-DOTC-1.2.hex tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LH-DOTC-1.2.bit
./multi_hex_to_bit hex/multi/${VER}/kawari_${VER}_${VER}_multi_LH-DOTC-1.5.hex tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LH-DOTC-1.5.bit

show_start_bytes tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LG_DVI-29MHZ-U.bit 2460500
show_start_bytes tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LG_DVI-27MHZ-S.bit 2460500
show_start_bytes tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LG_RGB-32MHZ-U.bit 2460500
show_start_bytes tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LH.bit 2410500
show_start_bytes tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LH-DOTC-1.2.bit 2410500
show_start_bytes tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LH-DOTC-1.5.bit 2410500

echo
echo "=================="
echo "Check start addrs"
echo "=================="
read n

strings tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LG_DVI-29MHZ-U.bit | grep Generated > tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LG_DVI-29MHZ-U.txt
strings tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LG_DVI-27MHZ-S.bit | grep Generated > tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LG_DVI-27MHZ-S.txt
strings tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LG_RGB-32MHZ-U.bit | grep Generated > tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LG_RGB-32MHZ-U.txt
strings tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LH.bit | grep Generated > tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LH.txt
strings tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LH-DOTC-1.2.bit | grep Generated > tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LH-DOTC-1.2.txt
strings tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LH-DOTC-1.5.bit | grep Generated > tmp/bit/${VER}/kawari_${VER}_${VER}_multi_LH-DOTC-1.5.txt

pushd tmp/bit/${VER} > /dev/null
grep Generated *.txt 
popd > /dev/null
echo "==========="
echo "Check dates"
echo "==========="
read n

echo
echo "Large - 29MHZ Unscaled"

./efinix_prep.sh hex/multi/${VER}/kawari_${VER}_${VER}_multi_LG_DVI-29MHZ-U.hex \
                 multiboot \
                 MAINLG-DVI-29MHZ-U \
                 ${VER}

./efinix_prep.sh hex/multi/${VER}/kawari_${VER}_${VER}_multi_LG_DVI-29MHZ-U.hex \
                 golden \
                 MAINLG-DVI-29MHZ-U \
                 ${VER}

echo "   Multiboot"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=${VER} FPGA=efinix_t20 START_ADDRESS=679936 IMAGE_SIZE=679936 TYPE=multiboot VARIANT=MAINLG-DVI-29MHZ-U PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile clean zip

echo "   Golden"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=${VER} FPGA=efinix_t20 START_ADDRESS=0 IMAGE_SIZE=679936 TYPE=golden VARIANT=MAINLG-DVI-29MHZ-U PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile clean zip

echo "Large - 27MHZ Scaled"

./efinix_prep.sh hex/multi/${VER}/kawari_${VER}_${VER}_multi_LG_DVI-27MHZ-S.hex \
                 multiboot \
                 MAINLG-DVI-27MHZ-S \
                 ${VER}

./efinix_prep.sh hex/multi/${VER}/kawari_${VER}_${VER}_multi_LG_DVI-27MHZ-S.hex \
                 golden \
                 MAINLG-DVI-27MHZ-S \
                 ${VER}

echo "   Multiboot"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=${VER} FPGA=efinix_t20 START_ADDRESS=679936 IMAGE_SIZE=679936 TYPE=multiboot VARIANT=MAINLG-DVI-27MHZ-S PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile clean zip

echo "   Golden"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=${VER} FPGA=efinix_t20 START_ADDRESS=0 IMAGE_SIZE=679936 TYPE=golden VARIANT=MAINLG-DVI-27MHZ-S PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile clean zip

echo "Large - 32MHZ RGB"

./efinix_prep.sh hex/multi/${VER}/kawari_${VER}_${VER}_multi_LG_RGB-32MHZ-U.hex \
                 multiboot \
                 MAINLG-RGB-32MHZ-U \
                 ${VER}

./efinix_prep.sh hex/multi/${VER}/kawari_${VER}_${VER}_multi_LG_RGB-32MHZ-U.hex \
                 golden \
                 MAINLG-RGB-32MHZ-U \
                 ${VER}

echo "   Multiboot"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=${VER} FPGA=efinix_t20 START_ADDRESS=679936 IMAGE_SIZE=679936 TYPE=multiboot VARIANT=MAINLG-RGB-32MHZ-U PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile clean zip

echo "   Golden"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=${VER} FPGA=efinix_t20 START_ADDRESS=0 IMAGE_SIZE=679936 TYPE=golden VARIANT=MAINLG-RGB-32MHZ-U PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile clean zip


echo "Mini - Baseline"

./efinix_prep.sh hex/multi/${VER}/kawari_${VER}_${VER}_multi_LH.hex \
                 multiboot \
                 MAINLH \
                 ${VER}

./efinix_prep.sh hex/multi/${VER}/kawari_${VER}_${VER}_multi_LH.hex \
                 golden \
                 MAINLH \
                 ${VER}

echo "   Multiboot"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=${VER} FPGA=efinix_t20 START_ADDRESS=659456 IMAGE_SIZE=659456 TYPE=multiboot VARIANT=MAINLH PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile clean zip

echo "   Golden"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=${VER} FPGA=efinix_t20 START_ADDRESS=0 IMAGE_SIZE=659456 TYPE=golden VARIANT=MAINLH PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile clean zip

echo "Mini - DOTC-1.2"

./efinix_prep.sh hex/multi/${VER}/kawari_${VER}_${VER}_multi_LH-DOTC-1.2.hex \
                 multiboot \
                 MAINLH-DOTC-1.2 \
                 ${VER}

./efinix_prep.sh hex/multi/${VER}/kawari_${VER}_${VER}_multi_LH-DOTC-1.2.hex \
                 golden \
                 MAINLH-DOTC-1.2 \
                 ${VER}

echo "   Multiboot"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=${VER} FPGA=efinix_t20 START_ADDRESS=659456 IMAGE_SIZE=659456 TYPE=multiboot VARIANT=MAINLH-DOTC-1.2 PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile clean zip

echo "   Golden"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=${VER} FPGA=efinix_t20 START_ADDRESS=0 IMAGE_SIZE=659456 TYPE=golden VARIANT=MAINLH-DOTC-1.2 PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile clean zip

echo "Mini - DOTC-1.5"

./efinix_prep.sh hex/multi/${VER}/kawari_${VER}_${VER}_multi_LH-DOTC-1.5.hex \
                 multiboot \
                 MAINLH-DOTC-1.5 \
                 ${VER}

./efinix_prep.sh hex/multi/${VER}/kawari_${VER}_${VER}_multi_LH-DOTC-1.5.hex \
                 golden \
                 MAINLH-DOTC-1.5 \
                 ${VER}

echo "   Multiboot"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=${VER} FPGA=efinix_t20 START_ADDRESS=659456 IMAGE_SIZE=659456 TYPE=multiboot VARIANT=MAINLH-DOTC-1.5 PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile clean zip

echo "   Golden"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=${VER} FPGA=efinix_t20 START_ADDRESS=0 IMAGE_SIZE=659456 TYPE=golden VARIANT=MAINLH-DOTC-1.5 PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile clean zip

