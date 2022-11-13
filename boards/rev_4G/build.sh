#!/bin/sh
mkdir -p build

MAJ=1
MIN=8

VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=MAINLG make clean all > build/MAINLG.${MAJ}.${MIN}.log
cat outflow/vicii.timing.rpt | grep Slack -B4 > build/MAINLG.timing.txt

VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=DOTCLG make clean all > build/DOTCLG.${MAJ}.${MIN}.log
cat outflow/vicii.timing.rpt | grep Slack -B4 > build/DOTCLG.timing.txt

VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=MKIILG make clean all > build/MKIILG.${MAJ}.${MIN}.log
cat outflow/vicii.timing.rpt | grep Slack -B4 > build/MKIILG.timing.txt

VERSION_MAJOR=${MAJ} VERSION_MINOR=${MIN} VARIANT=SARULG make clean all > build/SARULG.${MAJ}.${MIN}.log
cat outflow/vicii.timing.rpt | grep Slack -B4 > build/SARULG.timing.txt

