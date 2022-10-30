#!/bin/sh
mkdir -p build

MAJ=1
MIN=8

VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=MAINLH make clean all > build/MAINLH.${MAJ}.${MIN}.log
VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=DOTCLH make clean all > build/DOTCLH.${MAJ}.${MIN}.log
VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=MKIILH make clean all > build/MKIILH.${MAJ}.${MIN}.log
VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=SARULH make clean all > build/SARULH.${MAJ}.${MIN}.log
