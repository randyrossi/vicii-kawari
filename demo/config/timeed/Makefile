all: timeed.prg

OBJS=../main.o menu.o ../util.o ../init.o

timeed.prg: ../main.o menu.o ../util.o ../init.o
	cl65 -o timeed.prg ../main.o menu.o ../util.o ../init.o

../main.o: ../main.c ../../common/util.h
	cl65 --include-dir ../../common -c ../main.c -o ../main.o

../init.o: ../init.c ../../common/init.h
	cl65 --include-dir ../../common -c ../init.c -o ../init.o

../util.o: ../util.c ../../common/util.h
	cl65 --include-dir ../../common -c ../util.c -o ../util.o

menu.o: menu.c ../../common/util.h ../../common/kawari.h
	cl65 --include-dir ../../common -c menu.c -o menu.o

run:
	x64sc timeed.prg

clean:
	rm -f *.o timeed.prg
