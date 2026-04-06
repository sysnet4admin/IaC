#!/usr/bin/env bash

# Harbor v2.15.0 arm64 image builder
# Author-only script — not book content
#
# Usage:
#   bash build.sh          # build + push all
#   bash build.sh --build  # build only (no push)
#   bash build.sh --push   # push only (images already built)
#
# Prerequisites:
#   - arm64 host (Apple Silicon or arm64 Linux)
#   - docker login to sysnet4admin (docker login)
#   - ~20GB free disk space, stable internet

set -e

# ── configuration ────────────────────────────────────────────────
HARBOR_VERSION="v2.15.0"
TAG="${HARBOR_VERSION}-arm64"
NAMESPACE="sysnet4admin"
HARBOR_REPO="https://github.com/goharbor/harbor.git"
BUILD_DIR="$(pwd)/harbor-src"

IMAGES=(
  prepare
  harbor-core
  harbor-portal
  harbor-db
  harbor-registryctl
  harbor-log
  harbor-jobservice
  harbor-exporter
  registry-photon
  nginx-photon
  redis-photon
)
# ────────────────────────────────────────────────────────────────

DO_BUILD=true
DO_PUSH=true

for arg in "$@"; do
  case $arg in
    --build) DO_PUSH=false ;;
    --push)  DO_BUILD=false ;;
  esac
done

# ── guard: arm64 only ────────────────────────────────────────────
if [ "$(uname -m)" != "arm64" ] && [ "$(uname -m)" != "aarch64" ]; then
  echo "ERROR: This script must run on an arm64 host (detected: $(uname -m))"
  exit 1
fi

# ── build ────────────────────────────────────────────────────────
if [ "$DO_BUILD" = true ]; then
  echo "[1/4] Clone Harbor ${HARBOR_VERSION} source"
  if [ -d "$BUILD_DIR" ]; then
    echo "  → $BUILD_DIR already exists, skipping clone"
  else
    git clone --depth 1 -b ${HARBOR_VERSION} ${HARBOR_REPO} ${BUILD_DIR}
  fi

  echo "[2/4] Patch exporter Dockerfile (remove hardcoded GOARCH=amd64)"
  sed -i '' 's/ENV GOARCH=amd64/ENV GOARCH=arm64/' ${BUILD_DIR}/make/photon/exporter/Dockerfile
  grep "GOARCH" ${BUILD_DIR}/make/photon/exporter/Dockerfile

  echo "[3/4] Compile Harbor binaries (gen_apis + Go build in containers)"
  cd ${BUILD_DIR}
  make compile \
    -e DEVFLAG=false \
    -e VERSIONTAG=${TAG} \
    -e IMAGENAMESPACE=${NAMESPACE}

  echo "[3/4] Build Harbor images for arm64"
  make build \
    -e DEVFLAG=false \
    -e VERSIONTAG=${TAG} \
    -e BASEIMAGETAG=${TAG} \
    -e IMAGENAMESPACE=${NAMESPACE} \
    -e BASEIMAGENAMESPACE=${NAMESPACE} \
    -e BUILD_BASE=true \
    -e PULL_BASE_FROM_DOCKERHUB=false \
    -e TRIVYFLAG=false
  cd -

  echo "[4/4] Build complete. Images:"
  for img in "${IMAGES[@]}"; do
    docker images "${NAMESPACE}/${img}:${TAG}" --format "  {{.Repository}}:{{.Tag}} ({{.Size}})"
  done
fi

# ── push ─────────────────────────────────────────────────────────
if [ "$DO_PUSH" = true ]; then
  echo "[PUSH] Pushing ${#IMAGES[@]} images to DockerHub as ${NAMESPACE}/...:${TAG}"
  for img in "${IMAGES[@]}"; do
    echo "  → pushing ${NAMESPACE}/${img}:${TAG}"
    docker push "${NAMESPACE}/${img}:${TAG}"
  done
  echo "[PUSH] Done."
fi
