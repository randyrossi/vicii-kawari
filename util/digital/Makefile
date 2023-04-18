all: sound.prg

delay.inc:
	#cp delay_8k.inc delay.inc
	cp delay_10k.inc delay.inc
	#cp delay_14k.inc delay.inc

compressed.bin: compress.py
	#python3 compress.py samples/Office_8k.aiff
	python3 compress.py samples/NoSugar_10k.aiff
	#python3 compress.py samples/Superman_14k.aiff

sound.prg: sound.asm compressed.bin centroids1.bin centroids2.bin centroids3.bin centroids4.bin delay.inc
	acme --cpu 6510 sound.asm

clean:
	rm -f sound.prg compressed.bin centroids1.bin centroids2.bin centroids3.bin centroids4.bin reconstructed.aiff delay.inc
