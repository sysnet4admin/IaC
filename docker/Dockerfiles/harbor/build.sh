#!/usr/bin/env bash

# Harbor arm64 image builder
# Author-only script — not book content
#
# Usage:
#   bash build.sh                          # build + push all (default v2.10.0)
#   bash build.sh --build                  # build only (no push)
#   bash build.sh --push                   # push only (images already built)
#   HARBOR_VERSION=v2.15.0 bash build.sh   # build a different version
#
# Prerequisites:
#   - arm64 host (Apple Silicon or arm64 Linux)
#   - docker login to sysnet4admin (docker login)
#   - ~20GB free disk space, stable internet

set -e

# ── configuration ────────────────────────────────────────────────
# 원고 버전 변경 최소화 정책에 따라 기본값은 v2.10.0.
# v2.15.0 등 다른 버전이 필요하면 HARBOR_VERSION 환경변수로 오버라이드.
HARBOR_VERSION="${HARBOR_VERSION:-v2.10.0}"
TAG="${HARBOR_VERSION}-arm64"
NAMESPACE="sysnet4admin"
HARBOR_REPO="https://github.com/goharbor/harbor.git"
BUILD_DIR="$(pwd)/harbor-src-${HARBOR_VERSION}"

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

  # arm64 패치: gen_apis의 lint_apis 의존성 제거.
  # lint_apis는 spectral(amd64 전용 바이너리) 이미지로 swagger yaml을 "검증만" 하는 단계라
  # arm64 호스트에서 rosetta 실행 오류(ld-linux-x86-64.so.2)로 죽는다. 산출물이 없어 건너뛰어도 안전.
  # 실제 코드 생성을 하는 swagger 이미지는 golang 소스 빌드라 arm64 네이티브로 동작.
  echo "[2/4] Patch Makefile (drop amd64-only spectral lint from gen_apis)"
  sed -i '' 's/^gen_apis: lint_apis/gen_apis:/' ${BUILD_DIR}/Makefile
  grep -n "^gen_apis:" ${BUILD_DIR}/Makefile

  # 시간 드리프트 패치: prepare 베이스의 pipenv 버전 상향.
  # photon:5.0 롤링 저장소가 python 3.14를 깔면서 v2.10.0이 핀한 pipenv==2022.1.8이
  # pkgutil.ImpImporter(3.12에서 삭제됨) 참조로 crash. upstream이 v2.15.0에서 쓴 2025.0.3으로 교체.
  # 2022.1.8만 노려 치환하므로 이미 2025.x인 버전에는 영향 없음. 빌드타임 전용(런타임 무관).
  echo "[2/4] Patch prepare base (bump pipenv for python 3.14 compatibility)"
  sed -i '' 's/pipenv==2022.1.8/pipenv==2025.0.3/' ${BUILD_DIR}/make/photon/prepare/Dockerfile.base
  grep -n "pipenv==" ${BUILD_DIR}/make/photon/prepare/Dockerfile.base

  # 시간 드리프트 패치: db 베이스에서 postgresql13-server 설치 줄 제거.
  # photon:5.0의 libxml2가 2.15(.so.16)로 올라가 옛 libxml2.so.2에 의존하는 postgresql13이
  # 설치 불가("nothing provides libxml2.so.2"). pg13은 pg_upgrade 하위호환(pg13 데이터→pg14)용일 뿐
  # 런타임은 pg14이며, 책의 신규 설치는 pg14를 fresh init하므로 pg13 불필요. pg14 install 줄은 유지.
  echo "[2/4] Patch db base (drop uninstallable postgresql13-server)"
  sed -i '' '/tdnf install -y postgresql13-server/d' ${BUILD_DIR}/make/photon/db/Dockerfile.base
  grep -n "postgresql1" ${BUILD_DIR}/make/photon/db/Dockerfile.base

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
