all: util.o init.o main.o

util.o: util.c ../include/util.h
	cl65 --include-dir ../include -c util.c -o util.o

init.o: init.c ../include/init.h
	cl65 --include-dir ../include -c init.c -o init.o

main.o: main.c ../include/menu.h
	cl65 --include-dir ../include -c main.c -o main.o

clean:
	rm -f *.o
