all: field grogu horse view_chargen make_colors

conv_320x200.class: Conv320X200.java
	javac Conv320X200.java

conv_640x200.class: Conv640X200.java
	javac Conv640X200.java

field: conv_320x200.class
	java Conv320X200 320x200.png > 320colors-field.bin
	od -v -t x1 320x200.bin | sed 's/^........//' | head -2048 > ../simulator/hires10-field.hex
	cp 320colors-field.bin ../simulator

grogu: conv_320x200.class
	java Conv320X200 320x200-grogu.png > 320colors-grogu.bin
	od -v -t x1 320x200.bin | sed 's/^........//' | head -2048 > ../simulator/hires10-grogu.hex
	cp 320colors-grogu.bin ../simulator
	javac Conv640X200.java

horse: conv_640x200.class
	java Conv640X200 640x200.png > 640colors.bin
	od -v -t x1 640x200.bin | sed 's/^........//' | head -2048 > ../simulator/hires11.hex
	cp 640colors.bin ../simulator

inputs_for_prg: field grogu horse
	java Conv320X200 320x200.png -h > 320colors.hex
	cp 320x200.bin ../asm/field.bin
	java Conv320X200 320x200-grogu.png -h > 320colors-grogu.hex
	cp 320x200.bin ../asm/grogu.bin
	java Conv640X200 640x200.png -h > 640colors.hex
	cp 640x200.bin ../asm/horse.bin
	rm -f ../asm/field-col.bin
	xxd -r -p 320colors.hex ../asm/field-col.bin
	rm -f ../asm/grogu-col.bin
	xxd -r -p 320colors-grogu.hex ../asm/grogu-col.bin
	rm -f ../asm/horse-col.bin
	xxd -r -p 640colors.hex ../asm/horse-col.bin

%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

view_chargen: view_chargen.o
	gcc -o view_chargen view_chargen.o

make_colors: make_colors.o
	gcc -o make_colors make_colors.o -lm

make_luma_bin: make_luma_bin.o
	gcc -o make_luma_bin make_luma_bin.o

make_luma_levels: make_luma_levels.o
	gcc -o make_luma_levels make_luma_levels.o -lm

clean:
	rm -f *.o *.class *.bin a.out hires *.hex make_luma_bin make_colors make_luma_levels
