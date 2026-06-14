# dashboard-bluegreen — multi-platform build management
# Source: https://github.com/k8s-edu/Bkv2_sub_dashboard (branch: main)
#
# Builds the blue-green deployment demo dashboard in two variants (blue/green)
# selected at build time via the PHASE build-arg, and pushes multi-arch
# (amd64 + arm64) manifests to Docker Hub.

IMAGE     ?= sysnet4admin/dashboard
PLATFORMS ?= linux/amd64,linux/arm64
BUILDER   ?= multiarch

.PHONY: all blue green builder login

# Build & push both variants
all: blue green

# blue variant
blue:
	docker buildx build --builder $(BUILDER) --platform $(PLATFORMS) \
	  --build-arg PHASE=blue -t $(IMAGE):blue --push .

# green variant
green:
	docker buildx build --builder $(BUILDER) --platform $(PLATFORMS) \
	  --build-arg PHASE=green -t $(IMAGE):green --push .

# Create the multi-arch buildx builder if it does not exist
builder:
	docker buildx inspect $(BUILDER) >/dev/null 2>&1 || \
	  docker buildx create --name $(BUILDER) --driver docker-container --use

login:
	docker login
