all: mathtest.prg

OBJS=../main.o menu.o ../util.o ../init.o \
     test_umult.o \
     test_smult.o \
     test_udiv.o \
     test_sdiv.o \
     test_uadd.o \
     test_sadd.o \
     test_usub.o \
     test_ssub.o

mathtest.prg: $(OBJS)
	cl65 -o mathtest.prg $(OBJS)

../main.o: ../main.c ../../common/util.h
	cl65 --include-dir ../../common -c ../main.c -o ../main.o

../init.o: ../init.c ../../common/init.h
	cl65 --include-dir ../../common -c ../init.c -o ../init.o

../util.o: ../util.c ../../common/util.h
	cl65 --include-dir ../../common -c ../util.c -o ../util.o

menu.o: menu.c ../../common/util.h ../../common/kawari.h
	cl65 --include-dir ../../common -c menu.c -o menu.o

test_%.o: test_%.c
	cl65 --include-dir ../../common -o $@ -c $<

run:
	x64sc mathtest.prg

clean:
	rm -f *.o mathtest.prg
