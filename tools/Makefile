all: view_chargen make_colors
	javac Conv320X200.java
	java Conv320X200 320x200.png > 320colors-grogu.bin
	cp 320x200_0.bin hires
	cat 320x200_1.bin >> hires
	od -v -t x1 hires | sed 's/^........//' | head -2048 > ../simulator/hires10-field.hex
	mv 320colors-field.bin ../simulator
	java Conv320X200 320x200-grogu.png > 320colors-grogu.bin
	cp 320x200_0.bin hires
	cat 320x200_1.bin >> hires
	od -v -t x1 hires | sed 's/^........//' | head -2048 > ../simulator/hires10-grogu.hex
	mv 320colors-grogu.bin ../simulator/320colors-grogu.bin
	javac Conv640X200.java
	java Conv640X200 640x200.png > 640colors.bin
	cp 640x200_0.bin hires
	cat 640x200_1.bin >> hires
	od -v -t x1 hires | sed 's/^........//' | head -2048 > ../simulator/hires11.hex
	mv 640colors.bin ../simulator

just_colors:
	java Conv320X200 320x200.png -h > 320colors.hex
	java Conv320X200 320x200-grogu.png -h > 320colors-grogu.hex
	java Conv640X200 640x200.png -h > 640colors.hex
	xxd -r -p 320colors.hex ../asm/field-col.bin
	xxd -r -p 320colors-grogu.hex ../asm/grogu-col.bin
	xxd -r -p 640colors.hex ../asm/horse-col.bin

%.o: %.c $(DEPS)
	$(CC) -c -o $@ $< $(CFLAGS)

view_chargen: view_chargen.o
	gcc -o view_chargen view_chargen.o

make_colors: make_colors.o
	gcc -o make_colors make_colors.o

clean:
	rm -f *.class *.bin a.out hires *.hex
