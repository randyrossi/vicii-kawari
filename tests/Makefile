all: list.txt index.html

index.html: MakeReport.java
	javac MakeReport.java
	java MakeReport > index.html

list.txt:
	find VICII -name '*.prg' -type f > list.txt
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
	sudo mkdir -p /var/www/html/tests/VICII
	sudo mkdir -p /var/www/html/tests/snapshots
	sudo cp -R VICII/* /var/www/html/tests/VICII
	sudo cp -R snapshots/* /var/www/html/tests/snapshots
	sudo cp index.html /var/www/html
	sudo chown -R root:root  /var/www/html/*
	sudo chmod -R oug+rw /var/www/html/*
	sudo find /var/www/html -type d -exec chmod oug+x {} \;
