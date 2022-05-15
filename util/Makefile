all: rgb2hsv Sine.class MakeImage.class

rgb2hsv: rgb2hsv.o
	$(CC) -o $@ $< -lm 

%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

%.class: %.java
	javac $<

clean:
	rm -f *.o *.class rgb2hsv
