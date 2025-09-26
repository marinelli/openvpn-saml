VERSION ?= $(shell cat openvpn/version)

all: build

build:
	@docker build --file openvpn/Dockerfile.build --progress plain --output bin/ \
	  --build-arg VERSION=$(VERSION) .

addpatch:
	@docker build --file openvpn/Dockerfile.patches --progress plain --output openvpn/patches/ \
	  --build-arg VERSION_A=$(VERSION_A) --build-arg VERSION_B=$(VERSION_B) .

.PHONY: clean
clean:
	@find bin/ -mindepth 1 -maxdepth 1 -type f -not -path '*/.*' -print0 | xargs -r0 rm -v
