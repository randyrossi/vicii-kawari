#!/bin/sh
mkdir -p build

MAJ=1
MIN=8

VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=MAINLG make clean all > build/MAINLH.${MAJ}.${MIN}.log
VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=DOTCLG make clean all > build/DOTCLH.${MAJ}.${MIN}.log
VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=MKIILG make clean all > build/MKIILH.${MAJ}.${MIN}.log
VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=SARULG make clean all > build/SARULH.${MAJ}.${MIN}.log

