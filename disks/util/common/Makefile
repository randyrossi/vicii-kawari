all: util.o init.o main.o flash.o color.o hires.o

util.o: util.c ../include/util.h
	cl65 --include-dir ../include -c util.c -o util.o

init.o: init.c ../include/init.h
	cl65 --include-dir ../include -c init.c -o init.o

data.o: data.c ../include/data.h
	cl65 --include-dir ../include -c data.c -o data.o

main.o: main.c ../include/menu.h
	cl65 --include-dir ../include -c main.c -o main.o

flash.o: flash.c ../include/flash.h
	cl65 --include-dir ../include -c flash.c -o flash.o

color.o: color.c ../include/color.h
	cl65 --include-dir ../include -c color.c -o color.o

hires.o: hires.c ../include/color.h
	cl65 --include-dir ../include -c hires.c -o hires.o

clean:
	rm -f *.o
