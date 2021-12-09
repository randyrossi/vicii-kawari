include Makefile.inc

clean_all: clean
	${MAKE} -C rev_3 clean
	${MAKE} -C rev_4L clean
	${MAKE} -C rev_4S clean
	rm -rf hdl/config.vh.bak
