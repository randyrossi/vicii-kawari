all: kawari_demo_1

kawari_demo_1: subdirs
	truncate -s 174848 kawari_demo_1.d64
	c1541 -attach kawari_demo_1.d64 -format "vicii-kawari-d1",0
	c1541 -attach kawari_demo_1.d64 -write ball/ball.prg  ball
	c1541 -attach kawari_demo_1.d64 -write hires/grogu.prg  grogu-img
	c1541 -attach kawari_demo_1.d64 -write hires/horse.prg  horse-img
	c1541 -attach kawari_demo_1.d64 -write split/split.prg  split320
	c1541 -attach kawari_demo_1.d64 -list

subdirs:
	$(MAKE) -C ball
	$(MAKE) -C hires
	$(MAKE) -C split

clean:
	$(MAKE) -C ball clean
	$(MAKE) -C hires clean
	$(MAKE) -C split clean
	rm -f *.d64
