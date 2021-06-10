all: rgbed.prg

OBJS=../main.o menu.o ../util.o ../init.o

rgbed.prg: ../main.o menu.o ../util.o ../init.o
	cl65 -o rgbed.prg ../main.o menu.o ../util.o ../init.o

../main.o: ../main.c ../../common/util.h
	cl65 --include-dir ../../common -c ../main.c -o ../main.o

../init.o: ../init.c ../../common/init.h
	cl65 --include-dir ../common -c ../init.c -o ../init.o

menu.o: menu.c ../../common/util.h ../../common/kawari.h
	cl65 --include-dir ../../common -c menu.c -o menu.o

run:
	x64sc rgbed.prg

clean:
	rm -f *.o rgbed.prg
