# Makefile for asm64
# Copyright (C) 1996 by Nick Rossi

CC=	gcc
CPP=	g++

CFLAGS=	-g -funroll-loops

ASMOBJ=	asm64.o asm64Line.o asm64Label.o asm64Block.o asm64Macro.o

all:		asm64 token64
		cp asm64 token64 $(HOME)

token64:	token.cc token.h
		$(CPP) $(CFLAGS) token.cc -o token64

asm64:		$(ASMOBJ)
		$(CPP) $(CFLAGS) $(ASMOBJ) -o asm64

asm64.o:	asm64.cc asm64.h
		$(CPP) $(CFLAGS) -c asm64.cc

asm64Line.o:	asm64Line.cc asm64.h
		$(CPP) $(CFLAGS) -c asm64Line.cc

asm64Label.o:	asm64Label.cc asm64.h
		$(CPP) $(CFLAGS) -c asm64Label.cc

asm64Block.o:	asm64Block.cc asm64.h
		$(CPP) $(CFLAGS) -c asm64Block.cc

asm64Macro.o:	asm64Macro.cc asm64.h
		$(CPP) $(CFLAGS) -c asm64Macro.cc
