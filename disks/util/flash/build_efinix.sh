echo "Large - 29MHZ Unscaled"

./efinix_prep.sh hex/multi/1.17/kawari_1.17_1.17_multi_LG_DVI-29MHZ-U.hex \
                 multiboot \
                 MAINLG-DVI-29MHZ-U \
                 1.17

./efinix_prep.sh hex/multi/1.17/kawari_1.17_1.17_multi_LG_DVI-29MHZ-U.hex \
                 golden \
                 MAINLG-DVI-29MHZ-U \
                 1.17

echo "   Multiboot"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=1.17 FPGA=efinix_t20 START_ADDRESS=679936 IMAGE_SIZE=679936 TYPE=multiboot VARIANT=MAINLG-DVI-29MHZ-U PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile.inc clean zip

echo "   Golden"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=1.17 FPGA=efinix_t20 START_ADDRESS=0 IMAGE_SIZE=679936 TYPE=golden VARIANT=MAINLG-DVI-29MHZ-U PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile.inc clean zip

echo "Large - 27MHZ Scaled"

./efinix_prep.sh hex/multi/1.17/kawari_1.17_1.17_multi_LG_DVI-27MHZ-S.hex \
                 multiboot \
                 MAINLG-DVI-27MHZ-S \
                 1.17

./efinix_prep.sh hex/multi/1.17/kawari_1.17_1.17_multi_LG_DVI-27MHZ-S.hex \
                 golden \
                 MAINLG-DVI-27MHZ-S \
                 1.17

echo "   Multiboot"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=1.17 FPGA=efinix_t20 START_ADDRESS=679936 IMAGE_SIZE=679936 TYPE=multiboot VARIANT=MAINLG-DVI-27MHZ-S PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile.inc clean zip

echo "   Golden"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=1.17 FPGA=efinix_t20 START_ADDRESS=0 IMAGE_SIZE=679936 TYPE=golden VARIANT=MAINLG-DVI-27MHZ-S PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile.inc clean zip


echo "Mini - Baseline"

./efinix_prep.sh hex/multi/1.16/kawari_1.16_1.16_multi_LH.hex \
                 multiboot \
                 MAINLH \
                 1.16

./efinix_prep.sh hex/multi/1.16/kawari_1.16_1.16_multi_LH.hex \
                 golden \
                 MAINLH \
                 1.16

echo "   Multiboot"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=1.16 FPGA=efinix_t20 START_ADDRESS=659456 IMAGE_SIZE=659456 TYPE=multiboot VARIANT=MAINLH PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile.inc clean zip

echo "   Golden"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=1.16 FPGA=efinix_t20 START_ADDRESS=0 IMAGE_SIZE=659456 TYPE=golden VARIANT=MAINLH PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile.inc clean zip

echo "Mini - DOTC-1.2"

./efinix_prep.sh hex/multi/1.16/kawari_1.16_1.16_multi_LH-DOTC-1.2.hex \
                 multiboot \
                 MAINLH-DOTC-1.2 \
                 1.16

./efinix_prep.sh hex/multi/1.16/kawari_1.16_1.16_multi_LH-DOTC-1.2.hex \
                 golden \
                 MAINLH-DOTC-1.2 \
                 1.16

echo "   Multiboot"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=1.16 FPGA=efinix_t20 START_ADDRESS=659456 IMAGE_SIZE=659456 TYPE=multiboot VARIANT=MAINLH-DOTC-1.2 PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile.inc clean zip

echo "   Golden"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=1.16 FPGA=efinix_t20 START_ADDRESS=0 IMAGE_SIZE=659456 TYPE=golden VARIANT=MAINLH-DOTC-1.2 PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile.inc clean zip

echo "Mini - DOTC-1.5"

./efinix_prep.sh hex/multi/1.16/kawari_1.16_1.16_multi_LH-DOTC-1.5.hex \
                 multiboot \
                 MAINLH-DOTC-1.5 \
                 1.16

./efinix_prep.sh hex/multi/1.16/kawari_1.16_1.16_multi_LH-DOTC-1.5.hex \
                 golden \
                 MAINLH-DOTC-1.5 \
                 1.16

echo "   Multiboot"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=1.16 FPGA=efinix_t20 START_ADDRESS=659456 IMAGE_SIZE=659456 TYPE=multiboot VARIANT=MAINLH-DOTC-1.5 PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile.inc clean zip

echo "   Golden"
DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=1.16 FPGA=efinix_t20 START_ADDRESS=0 IMAGE_SIZE=659456 TYPE=golden VARIANT=MAINLH-DOTC-1.5 PAGE_SIZE=4096 NUM_DISKS=5 make -f Makefile.inc clean zip

