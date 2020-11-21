all: list.txt index.html

index.html:
	javac MakeReport.java
	java MakeReport > index.html

list.txt:
	find . -name '*.prg' -type f > list.txt
	find . -name '*.vsf' -type f >> list.txt

clean:
	rm -f MakeReport.class
	rm -f list.txt
	rm -f index.html
	find . -name 'vice_*.png' -exec rm -f {} \;
	find . -name 'vice_*.log' -exec rm -f {} \;
	find . -name 'fpga_*.png' -exec rm -f {} \;
