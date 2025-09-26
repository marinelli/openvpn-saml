VERSION ?= $(shell cat openvpn/version)

all: build

build:
	docker build --file openvpn/Dockerfile.build --progress plain --output bin/ \
	  --build-arg VERSION=$(VERSION) .

addpatch:
	docker build --file openvpn/Dockerfile.patches --progress plain --output openvpn/patches/ \
	  --build-arg VERSION_A=$(VERSION_A) --build-arg VERSION_B=$(VERSION_B) .

.PHONY: clean
clean:
	rm -f bin/openvpn bin/openvpn.LICENSE bin/update-systemd-resolved bin/update-systemd-resolved.LICENSE
