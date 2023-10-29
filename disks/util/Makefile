# Make this match define in util.h
VERSION=1.6

all: kawari_util_$(VERSION)

kawari_util_$(VERSION): subdirs
	truncate -s 174848 kawari_util_$(VERSION).d64
	c1541 -attach kawari_util_$(VERSION).d64 -format "vicii-kawari-u1",0
	c1541 -attach kawari_util_$(VERSION).d64 -write config/config.prg config
	c1541 -attach kawari_util_$(VERSION).d64 -write config/quick/quickswitch.prg qs
	c1541 -attach kawari_util_$(VERSION).d64 -write config/rgbed/rgbed.prg rgbed
	c1541 -attach kawari_util_$(VERSION).d64 -write config/comped/comped.prg comped
	c1541 -attach kawari_util_$(VERSION).d64 -write config/eepromed/eepromed.prg eepromed
	c1541 -attach kawari_util_$(VERSION).d64 -write tests/regtest/regtest.prg regtest
	c1541 -attach kawari_util_$(VERSION).d64 -write tests/mathtest/mathtest.prg mathtest
	c1541 -attach kawari_util_$(VERSION).d64 -write tests/rgbtest/rgbtest.prg rgbtest
	c1541 -attach kawari_util_$(VERSION).d64 -write tests/lumatest/lumatest.prg lumatest
	#c1541 -attach kawari_util_$(VERSION).d64 -write tests/flashtest/flashtest.prg flashtest
	c1541 -attach kawari_util_$(VERSION).d64 -write 80col/80col-51200.prg 80col-51200
	c1541 -attach kawari_util_$(VERSION).d64 -write vmem/vmem-49152.prg vmem-49152
	c1541 -attach kawari_util_$(VERSION).d64 -write novaterm/kawari.ml 80col.kawari
	c1541 -attach kawari_util_$(VERSION).d64 -write ansii/ansii.prg ansii
	c1541 -attach kawari_util_$(VERSION).d64 -list

subdirs:
	$(MAKE) -C common
	$(MAKE) -C config
	$(MAKE) -C 80col
	$(MAKE) -C novaterm
	$(MAKE) -C tests
	$(MAKE) -C ansii

clean:
	$(MAKE) -C config clean
	$(MAKE) -C common clean
	$(MAKE) -C config clean
	$(MAKE) -C 80col clean
	$(MAKE) -C novaterm clean
	$(MAKE) -C tests clean
	$(MAKE) -C flash clean
	$(MAKE) -C ansii clean
	rm -f *.d64
