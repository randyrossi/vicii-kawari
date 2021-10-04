all: demo

demo: subdirs
	truncate -s 174848 demo.d64
	c1541 -attach demo.d64 -format "vicii-kawari-dem",0
	c1541 -attach demo.d64 -write ball/ball.prg  ball
	c1541 -attach demo.d64 -write hires/grogu.prg  grogu-img
	c1541 -attach demo.d64 -write hires/horse.prg  horse-img
	c1541 -attach demo.d64 -write split/split.prg  split320
	c1541 -attach demo.d64 -list

subdirs:
	$(MAKE) -C ball
	$(MAKE) -C hires
	$(MAKE) -C split

clean:
	$(MAKE) -C ball clean
	$(MAKE) -C hires clean
	$(MAKE) -C split clean
	rm -f demo.d64
