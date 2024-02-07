# A very hacky utility to create img and palette data
# compatible with krps 'viewer' program from
# a jpg.

all: img.bin rgb.bin

img.bin: wednesday.jpg src/Raster.java
	mkdir -p bin
	rm -rf tmp
	javac src/Raster.java -d bin
	java -cp bin Raster wednesday.jpg
	mv tmp/img.bin .

rgb.bin: img.bin
	mv tmp/rgb.bin .

clean:
	rm -rf *.class img.bin rgb.bin tmp bin
