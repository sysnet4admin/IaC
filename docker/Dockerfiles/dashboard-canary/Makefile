# dashboard-canary — multi-platform build management
# Source: https://github.com/k8s-edu/Bkv2_sub_dashboard (branch: canary)
#
# Builds the Argo Rollouts canary demo dashboard in two variants (v1/v2)
# selected at build time via the PHASE build-arg, and pushes multi-arch
# (amd64 + arm64) manifests to Docker Hub.

IMAGE     ?= sysnet4admin/dashboard
PLATFORMS ?= linux/amd64,linux/arm64
BUILDER   ?= multiarch

.PHONY: all v1 v2 builder login

# Build & push both variants
all: v1 v2

# v1: original dashboard UI
v1:
	docker buildx build --builder $(BUILDER) --platform $(PLATFORMS) \
	  --build-arg PHASE=v1 -t $(IMAGE):canary-v1 --push .

# v2: updated dashboard UI
v2:
	docker buildx build --builder $(BUILDER) --platform $(PLATFORMS) \
	  --build-arg PHASE=v2 -t $(IMAGE):canary-v2 --push .

# Create the multi-arch buildx builder if it does not exist
builder:
	docker buildx inspect $(BUILDER) >/dev/null 2>&1 || \
	  docker buildx create --name $(BUILDER) --driver docker-container --use

login:
	docker login
