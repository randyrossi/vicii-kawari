#!/bin/sh
mkdir -p build

MAJ=1
MIN=16

ALL="MAINLH MAINLH-DOTC"

for V in $ALL
do
   if [ "$1" = "sweep" ]
   then
      VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=${V} make clean sweep > build/${V}.${MAJ}.${MIN}_sweep.log
   else
      VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=${V} make clean all > build/${V}.${MAJ}.${MIN}.log
      cp outflow/vicii.timing.rpt build/${V}.${MAJ}.${MIN}.rpt
   fi
done
