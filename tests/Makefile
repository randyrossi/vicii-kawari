all: list.txt index.html

index.html: MakeReport.java
	javac MakeReport.java
	java MakeReport > index.html

list.txt:
	find VICII_Old -name '*.prg' -type f > list.txt
	find . -name '*.vsf' -type f >> list.txt

clean:
	rm -f MakeReport.class
	rm -f list.txt
	rm -f index.html

clean_results:
	find . -name 'vice_*.png' -exec rm -f {} \;
	find . -name 'vice_*.log' -exec rm -f {} \;
	find . -name 'fpga_*.png' -exec rm -f {} \;

publish:
	sudo cp -R * /var/www/html/tests
	sudo cp index.html /var/www/html
	sudo chown -R root:root  /var/www/html/*
	sudo chmod -R oug+rw /var/www/html/*
	sudo find /var/www/html -type d -exec chmod oug+x {} \;
