#!/bin/bash

VER=1.20

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

make multi_hex_to_bit

# Format is:
# HEXFILE:BOOTS:OCTALOFFSET:SIZE:VARIANT:HUMANLABEL
#
#    HEXFILE must be a multi .hex created with efinity programming tool
#    BOOT multi=.hex was created as active/fallback multi image, else is single build
#    OCTALOFFSET is the octal offset within the .bit file containing the fallback pointer
#    SIZE of the .bit file created from .hex
#    VARIANT variant identifier
#    HUMANLABEL printed to stdout before each disk is created

ALL="hex/multi/${VER}/kawari_${VER}_${VER}_multi_LG_DVI-29MHZ-U.hex:multi:2460500:679936:MAINLG-DVI-29MHZ-U:Large-29MHZ_Unscaled \
  hex/multi/${VER}/kawari_${VER}_${VER}_multi_LG_DVI-27MHZ-S.hex:multi:2460500:679936:MAINLG-DVI-27MHZ-S:Large-27MHZ_Scaled \
  hex/multi/${VER}/kawari_${VER}_${VER}_multi_LG_RGB-32MHZ-U.hex:multi:2460500:679936:MAINLG-RGB-32MHZ-U:Large-32MHZ_RGB \
  hex/multi/${VER}/kawari_${VER}_${VER}_multi_LH.hex:multi:2410500:659456:MAINLH:Mini \
  hex/multi/${VER}/kawari_${VER}_${VER}_multi_LH-DOTC-1.2.hex:multi:2410500:659456:MAINLH-DOTC-1.2:Mini-DOTC-1.2 \
  hex/multi/${VER}/kawari_${VER}_${VER}_multi_LH-DOTC-1.5.hex:multi:2410500:659456:MAINLH-DOTC-1.5:Mini-DOTC-1.5"

# Example of building an active (multiboot) image
# from a single .hex file generated from a board build.
# Use this to bypass creating a multi .hex file with
# the efinity tool.
#ALL="../../../boards/rev_4H/build/kawari_multiboot_MAINLH_1.20.hex:single:2410500:659456:MAINLH:Mini"

for variant in $ALL
do
   IFS=: read -r file boot offset size name header <<< "$variant"

   if [ -f $file ]
   then
       echo $file "FOUND"
   else
       echo $file "MISSING!"
   fi
done

echo "========================================"
echo "Check source files above and press ENTER"
echo "========================================"
read n
echo
mkdir -p prep/bit/${VER}

# Only for the files actually found, perform the task
for variant in $ALL
do
   IFS=: read -r file boot offset size name header <<< "$variant"

   if [ -f $file ]
   then
      echo $file
      BASE=`basename $file .hex`
      BIT=prep/bit/${VER}/${BASE}.bit
      ./multi_hex_to_bit $file $BIT
      if [ $boot = "multi" ]
      then
         show_start_bytes $BIT $offset
      fi
      strings $BIT | grep Generated > $BIT.txt
      grep Generated $BIT.txt

   fi
done

echo "====================================="
echo "Check meta data above and press ENTER"
echo "====================================="
read n

echo "Creating disks..."
for variant in $ALL
do
   IFS=: read -r file boot offset size name header <<< "$variant"

   if [ -f $file ]
   then
      echo $header

      BASE=`basename $file .hex`
      BIT=prep/bit/${VER}/${BASE}.bit

      if [ $boot = "multi" ]
      then
         # .hex was created from efinix programming utility for active/fallback
         echo "   Multiboot"
         DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=${VER} STRIP=yes START_ADDRESS=$size IMAGE_SIZE=$size TYPE=multiboot VARIANT=$name PAGE_SIZE=4096 NUM_DISKS=5 BITFILE=${BIT} make -f Makefile clean zip

         echo "   Golden"
         DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=${VER} STRIP=yes START_ADDRESS=0 IMAGE_SIZE=$size TYPE=golden VARIANT=$name PAGE_SIZE=4096 NUM_DISKS=5 BITFILE=${BIT} make -f Makefile clean zip
      else
         # .hex was created from single image build, use as active
         echo "   Multiboot from single"
         DISKNUMS="1 2 3 4 5" NAME=kawari VERSION=${VER} STRIP=no START_ADDRESS=$size IMAGE_SIZE=$size TYPE=multiboot VARIANT=$name PAGE_SIZE=4096 NUM_DISKS=5 BITFILE=${BIT} make -f Makefile clean zip
      fi

   fi
done
