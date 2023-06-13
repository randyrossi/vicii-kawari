#!/bin/sh

# Used for Trion boards only
# This script will bypass the strip step from the usual Makefile process
# of creating a .bit file from a multi.hex file. Instead of creating
# a multi.hex file from two .hex builds (boot and fallback), this will create
# a build directly from a single .hex file in order to create a set of
# flash disks from that one file. NOTE: A fallback build is built differently
# from an active build, so you cannot mix the two types.  The .hex file
# must still be generated for either active or fallback.

# IMPORTANT
# Add suffix "_pre" to the FPGA env in each Makefile.* file you want to use.
# This will bypass the strip step.

SRC_DIR=../../../boards
VERSION=1.16

# List of BOARD:CODE:FILE to make flash disk sets for...
# FILE will be grabbed from the board build dir 
#VARIANTS="rev_4G:MAINLG-DVI:kawari_multiboot_MAINLG-DVI_${VERSION}.hex rev_4G:MAINLG-RGB:kawari_multiboot_MAINLG-RGB_${VERSION}.hex rev_4H:MAINLH:kawari_multiboot_MAINLH_${VERSION}.hex rev_4H:MAINLH-DOTC:kawari_multiboot_MAINLH-DOTC_${VERSION}.hex"

#VARIANTS="rev_4H:MAINLH:kawari_multiboot_MAINLH_${VERSION}.hex"
VARIANTS="rev_4G:MAINLG-DVI:kawari_multiboot_MAINLG-DVI_${VERSION}.hex"

for VARIANT in $VARIANTS
do
   IFS=':'
   BOARD=""
   CODE=""
   FILE=""
   for ENTRY in $VARIANT
   do
      if [ "$BOARD" = "" ]; then
         BOARD=$ENTRY
      elif [ "$CODE" = "" ]; then
         CODE=$ENTRY 
      elif [ "$FILE" = "" ]; then
         FILE=$ENTRY 
      fi
   done
   IFS=' '

   echo "Board:"$BOARD
   echo "Code :"$CODE
   echo "File :"$FILE

   HEX_FILE=${SRC_DIR}/${BOARD}/build/${FILE}

   echo "FILE: $HEX_FILE"
   echo -n "Press Return: "
   read n

   if [ ! -e "$HEX_FILE" ]
   then
      echo "File not found"
      exit
   fi

   make -f Makefile.${CODE} clean
   make multi_hex_to_bit

   ./multi_hex_to_bit $HEX_FILE stripped.bit

   SIZE=`wc -c stripped.bit | awk '{print $1}'`
   PAD=`echo "(($SIZE/4096)+1)*4096-$SIZE" | bc`
   dd if=/dev/zero ibs=$PAD count=1 | tr "\000" "\377" >> stripped.bit

   make -f Makefile.${CODE} zip
done
