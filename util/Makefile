all: rgb2hsv

rgb2hsv: rgb2hsv.o
	$(CC) -o $@ $<

%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)


clean:
	rm -f *.o rgb2hsv
