build:
	docker build --file Dockerfile.build --progress plain --output bin/ \
		--build-arg VERSION=$(VERSION) .

addpatch:
	docker build --file Dockerfile.patches --progress plain --output patches/ \
		--build-arg VERSION_A=$(VERSION_A) --build-arg VERSION_B=$(VERSION_B) .
