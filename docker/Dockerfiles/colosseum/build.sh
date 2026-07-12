#!/usr/bin/env bash
#
# colosseum 마이크로서비스 멀티아치 build & push
#
# upstream(k8s-edu/Bkv2_sub_colosseum)을 mktemp 임시 디렉터리에 clone한 뒤,
# 서비스별 Dockerfile을 목적에 맞게 빌드해서 Docker Hub에 푸시한다.
# agg는 한 소스에서 관측 옵션별로 3개 이미지(log/trace/profile)를 낸다.
#
# 사용법:
#   ./build.sh                # 전체 빌드/푸시
#   ./build.sh agg cms        # 지정한 서비스만 (이미지 태그 앞부분으로 필터)
#   DRY_RUN=1 ./build.sh      # 실제 빌드 없이 계획만 출력
#
# 환경변수:
#   REPO       upstream 저장소 URL (기본 https://github.com/k8s-edu/Bkv2_sub_colosseum)
#   REF        clone할 브랜치/태그/커밋 (기본 main). 고정하려면 커밋 해시 지정
#   NAMESPACE  이미지 네임스페이스 (기본 sysnet4admin)
#   PLATFORMS  빌드 플랫폼 (기본 linux/amd64,linux/arm64)
#   BUILDER    buildx 빌더 이름 (기본 multiarch, 없으면 생성)
#   PUSH       1이면 push, 0이면 로컬 로드 없이 빌드만(--push 생략) (기본 1)

set -euo pipefail

REPO="${REPO:-https://github.com/k8s-edu/Bkv2_sub_colosseum}"
REF="${REF:-main}"
NAMESPACE="${NAMESPACE:-sysnet4admin}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
BUILDER="${BUILDER:-multiarch}"
PUSH="${PUSH:-1}"
DRY_RUN="${DRY_RUN:-0}"

# 빌드 매핑: "서비스 소스 디렉터리|Dockerfile|이미지 리포:태그"
BUILDS=(
  "Bkv2_sub_colosseum-agg|Dockerfile.log|colosseum-agg:log"
  "Bkv2_sub_colosseum-agg|Dockerfile.trace|colosseum-agg:trace"
  "Bkv2_sub_colosseum-agg|Dockerfile.profile|colosseum-agg:profile"
  "Bkv2_sub_colosseum-cms|Dockerfile|colosseum-cms:log"
  "Bkv2_sub_colosseum-nti|Dockerfile|colosseum-nti:log"
  "Bkv2_sub_colosseum-prm|Dockerfile|colosseum-prm:log"
  "Bkv2_sub_colosseum-rwd|Dockerfile|colosseum-rwd:log"
)

log() { printf '\033[1;34m[colosseum]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[colosseum][ERROR]\033[0m %s\n' "$*" >&2; }

# 인자로 받은 서비스 필터(이미지 이름 앞부분 매칭). 없으면 전체.
FILTERS=("$@")
match() {
  [ ${#FILTERS[@]} -eq 0 ] && return 0
  local image="$1"
  for f in "${FILTERS[@]}"; do
    case "$image" in *"$f"*) return 0 ;; esac
  done
  return 1
}

# 사전 점검
command -v git >/dev/null || { err "git 필요"; exit 1; }
docker buildx version >/dev/null 2>&1 || { err "docker buildx 필요"; exit 1; }

# 멀티아치 빌더 준비 (docker 드라이버는 멀티플랫폼 push 불가)
if [ "$DRY_RUN" != "1" ]; then
  if ! docker buildx inspect "$BUILDER" >/dev/null 2>&1; then
    log "buildx 빌더 '$BUILDER' 생성"
    docker buildx create --name "$BUILDER" --driver docker-container --bootstrap >/dev/null
  fi
fi

# 임시 디렉터리에 소스 clone (스크립트 종료 시 정리)
WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/colosseum.XXXXXX")"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

log "clone $REPO ($REF) -> $WORKDIR"
if [ "$REF" = "main" ] || [ "$REF" = "master" ]; then
  git clone --depth 1 --branch "$REF" "$REPO" "$WORKDIR/src" >/dev/null 2>&1
else
  # 임의 커밋/태그도 받을 수 있도록 전체 clone 후 checkout
  git clone "$REPO" "$WORKDIR/src" >/dev/null 2>&1
  git -C "$WORKDIR/src" checkout --quiet "$REF"
fi
BUILT_REF="$(git -C "$WORKDIR/src" rev-parse --short HEAD)"
log "빌드 대상 커밋: $BUILT_REF"

ok=(); fail=()
for entry in "${BUILDS[@]}"; do
  IFS='|' read -r svc dockerfile repotag <<< "$entry"
  image="$NAMESPACE/$repotag"
  match "$image" || continue

  ctx="$WORKDIR/src/$svc"
  if [ ! -f "$ctx/$dockerfile" ]; then
    err "$svc/$dockerfile 없음 (upstream 구조 변경?) — 건너뜀"
    fail+=("$image (missing $dockerfile)")
    continue
  fi

  log "빌드: $image  <-  $svc/$dockerfile  [$PLATFORMS]"
  push_flag="--push"; [ "$PUSH" = "1" ] || push_flag=""

  if [ "$DRY_RUN" = "1" ]; then
    echo "  (dry-run) docker buildx build --builder $BUILDER --platform $PLATFORMS -f $dockerfile -t $image $push_flag ."
    ok+=("$image")
    continue
  fi

  # 각 서비스 폴더로 이동해서 빌드 (빌드 컨텍스트 = 서비스 소스 트리)
  if ( cd "$ctx" && docker buildx build \
        --builder "$BUILDER" \
        --platform "$PLATFORMS" \
        --provenance=false \
        -f "$dockerfile" \
        -t "$image" \
        $push_flag . ); then
    ok+=("$image")
  else
    err "빌드 실패: $image"
    fail+=("$image")
  fi
done

echo
log "완료 (커밋 $BUILT_REF)"
for i in "${ok[@]:-}";   do [ -n "$i" ] && printf '  \033[1;32mOK  \033[0m %s\n' "$i"; done
for i in "${fail[@]:-}"; do [ -n "$i" ] && printf '  \033[1;31mFAIL\033[0m %s\n' "$i"; done
[ ${#fail[@]} -eq 0 ] || { [ -n "${fail[0]:-}" ] && exit 1; }
