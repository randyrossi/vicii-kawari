#!/bin/sh
mkdir -p build

MAJ=1
MIN=17

ALL="MAINLG-DVI:29MHZ MAINLG-DVI:27MHZ MAINLG_RGB:32MHZ"
for V in $ALL
do
   IFS=':'
   VAR=""
   RES=""
   for ENTRY in $V
   do
      if [ "$VAR" = "" ]; then
         VAR=$ENTRY
      elif [ "$RES" = "" ]; then
         RES=$ENTRY
      fi
   done
   VAR=$VAR-$RES

   echo "Building $VAR..."

   cp vicii_${RES}.peri.xml vicii.peri.xml
   cp vicii_${RES}.sdc vicii.sdc

   if [ "$1" = "sweep" ]
   then
      VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=${VAR} make clean sweep > build/${VAR}.${MAJ}.${MIN}_sweep.log
   else
      VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=${VAR} make clean all > build/${VAR}.${MAJ}.${MIN}.log
      cp outflow/vicii.timing.rpt build/${VAR}.${MAJ}.${MIN}.rpt
   fi
done
