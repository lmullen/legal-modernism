start:
	make build-server; make run;

install:
	cd citation-detection; npm install; cd ..;

build:
	cd citation-detection; npm run build; cd ..;

run:
	node --optimize_for_size --max_old_space_size=460 --gc_interval=100 ./build/extraction.js;

clean:
	rm -rf ./citation-detection/build && rm -rf ./citation-detection/node_modules; 