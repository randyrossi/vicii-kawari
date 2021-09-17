all: demo

demo: subdirs
	truncate -s 174848 demo.d64
	c1541 -attach demo.d64 -format "vicii-kawaridemo",0
	c1541 -attach demo.d64 -write config/config.prg config
	c1541 -attach demo.d64 -write config/quick/quickswitch.prg qs
	c1541 -attach demo.d64 -write config/rgbed/rgbed.prg rgbed
	c1541 -attach demo.d64 -write config/comped/comped.prg comped
	c1541 -attach demo.d64 -write config/eepromed/eepromed.prg eepromed
	c1541 -attach demo.d64 -write config/test/test.prg test
	c1541 -attach demo.d64 -write config/mathtest/mathtest.prg mathtest
	c1541 -attach demo.d64 -write config/rgbtest/rgbtest.prg rgbtest
	c1541 -attach demo.d64 -write 80col/80col-51200.prg 80col-51200
	c1541 -attach demo.d64 -write ../asm/fade.prg fade
	c1541 -attach demo.d64 -write ../asm/grogu.prg img-grogu
	c1541 -attach demo.d64 -write ../asm/horse.prg img-horse
	c1541 -attach demo.d64 -write ../prg/palette.prg palette-test
	c1541 -attach demo.d64 -list

subdirs:
	$(MAKE) -C config

clean:
	$(MAKE) -C config clean
	rm -f demo.d64
