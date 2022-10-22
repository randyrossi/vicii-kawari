all: rgb2hsv Sine.class MakeImage.class

rgb2hsv: rgb2hsv.o
	$(CC) -o $@ $< -lm 

%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

%.class: %.java
	javac $<

make_bin_files: make_bin_files.c
	gcc -c ../disks/util/common/data.c -o data.o
	gcc -c make_bin_files.c -o make_bin_files.o
	gcc -o make_bin_files data.o make_bin_files.o

clean:
	rm -f *.o *.class rgb2hsv
