#!/bin/sh
mkdir -p build

MAJ=1
MIN=8

VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=MAINLG make clean all > build/MAINLG.${MAJ}.${MIN}.log
VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=DOTCLG make clean all > build/DOTCLG.${MAJ}.${MIN}.log
VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=MKIILG make clean all > build/MKIILG.${MAJ}.${MIN}.log
VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=SARULG make clean all > build/SARULG.${MAJ}.${MIN}.log

