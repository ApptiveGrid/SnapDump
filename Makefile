# make push REGISTRY=registry.example.org[:port] VERSION=0.9.2
# pushes <registry>/snap-dump:<version>; the registry is the caller's, there is no default.
REGISTRY ?=
VERSION ?= 0.9.2
# the VM of the Pharo 7 image is x86_64; on an arm64 host (a Mac) docker emulates it
PLATFORM ?= linux/amd64
IMAGE = $(REGISTRY)/snap-dump

# The Dockerfile copies source/ and loads it itself, so nothing is built locally first.
docker:
	@test -n "$(REGISTRY)" || { echo "REGISTRY is not set, e.g. make docker REGISTRY=registry.example.org"; exit 1; }
	docker build --platform $(PLATFORM) --build-arg VERSION=$(VERSION) -t $(IMAGE):$(VERSION) .

push: docker
	docker push $(IMAGE):$(VERSION)

clean:
	rm -f SnapDump.image SnapDump.changes
all: docker

.PHONY: docker push clean all
