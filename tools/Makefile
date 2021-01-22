all:
	javac Conv320X200.java
	java Conv320X200 > 320colors.bin
	cp 320x200_0.bin hires
	cat 320x200_1.bin >> hires
	od -v -t x1 hires | sed 's/^........//' | head -2048 > ../simulator/hires10.hex
	mv 320colors.bin ../simulator
	javac Conv640X200.java
	java Conv640X200 > 640colors.bin
	cp 640x200_0.bin hires
	cat 640x200_1.bin >> hires
	od -v -t x1 hires | sed 's/^........//' | head -2048 > ../simulator/hires11.hex
	mv 640colors.bin ../simulator

clean:
	rm -f *.class 320x200_0.bin 320x200_1.bin 640x200_0.bin 640x200_1.bin a.out
