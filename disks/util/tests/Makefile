all: subdirs

subdirs:
	$(MAKE) -C functest
	$(MAKE) -C lumatest
	$(MAKE) -C rgbtest
	$(MAKE) -C mathtest
	$(MAKE) -C regtest

clean:
	$(MAKE) -C functest clean
	$(MAKE) -C lumatest clean
	$(MAKE) -C rgbtest clean
	$(MAKE) -C mathtest clean
	$(MAKE) -C regtest clean
