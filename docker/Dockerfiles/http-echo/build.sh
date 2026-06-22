#!/usr/bin/env bash
# sysnet4admin/http-echo multi-arch image builder
#
# Run this on any host with docker buildx (Docker Desktop, or docker-ce + buildx plugin,
# or colima with buildx). No Docker Desktop required.
#
# Usage:
#   docker login -u sysnet4admin          # once
#   bash build.sh                         # build linux/amd64,linux/arm64 and push :1.0 + :latest
#   bash build.sh --load                  # build for the local arch only and load (no push, for testing)
#
# Test after build (local):
#   docker run --rm -e ECHO_TEXT="hello from Gateway API demo" -p 8080:80 sysnet4admin/http-echo:1.0
#   curl localhost:8080   # -> hello from Gateway API demo
set -euo pipefail

NAMESPACE="sysnet4admin"
IMAGE="http-echo"
VERSION="1.0"
PLATFORMS="linux/amd64,linux/arm64"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REF="${NAMESPACE}/${IMAGE}"

if [ "${1:-}" = "--load" ]; then
  echo "==> build (local arch, load into docker — no push)"
  docker buildx build --load -t "${REF}:${VERSION}" "${HERE}"
  echo "==> loaded ${REF}:${VERSION}"
  exit 0
fi

# Ensure a buildx builder that supports multi-arch exists.
if ! docker buildx inspect http-echo-builder >/dev/null 2>&1; then
  echo "==> create buildx builder 'http-echo-builder'"
  docker buildx create --name http-echo-builder --use
else
  docker buildx use http-echo-builder
fi
docker buildx inspect --bootstrap >/dev/null

echo "==> build ${PLATFORMS} and push ${REF}:${VERSION} + ${REF}:latest"
docker buildx build \
  --platform "${PLATFORMS}" \
  -t "${REF}:${VERSION}" \
  -t "${REF}:latest" \
  --push \
  "${HERE}"

echo "==> done. verify:"
echo "    docker buildx imagetools inspect ${REF}:${VERSION}"
