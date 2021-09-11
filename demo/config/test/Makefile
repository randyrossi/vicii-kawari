all: test.prg

OBJS=../main.o menu.o ../util.o ../init.o \
     test_auto_inc_vmem_a.o \
     test_auto_inc_vmem_b.o \
     test_auto_dec_vmem_a.o \
     test_auto_dec_vmem_b.o \
     test_noop_vmem.o \
     test_vmem.o \
     test_vmem_idx.o \
     test_copy.o \
     test_fill.o

test.prg: $(OBJS)
	cl65 -o test.prg $(OBJS)

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
	x64sc test.prg

clean:
	rm -f *.o test.prg
