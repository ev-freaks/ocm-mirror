all: clean build

.PNONY: all clean build

build:
	docker build -t ocm-mirror .

clean:
	docker image rm ocm-mirror
