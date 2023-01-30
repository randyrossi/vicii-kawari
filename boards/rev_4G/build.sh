#!/bin/sh
mkdir -p build

MAJ=1
MIN=14

ALL="MAINLG_DVI MAINLG_RGB"
for V in $ALL
do
   VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=${V} make clean all > build/${V}.${MAJ}.${MIN}.log
done
