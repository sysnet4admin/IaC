# Dockerfiles 빌드 규약

이 디렉터리의 이미지는 대부분 `_Book_k8sInfra`(책)와 `_Lecture_*`(강의 kit) 실습에서
직접 참조한다. 독자 환경에는 x86_64 PC와 Apple Silicon 맥이 섞여 있으므로 아래 규약을 지킨다.

## 1. 멀티 플랫폼 빌드가 기본이다

`docker build`를 쓰지 않는다. 항상 buildx로 두 아키텍처를 함께 빌드해 푸시한다.

```bash
docker buildx build --platform linux/amd64,linux/arm64 \
  -t sysnet4admin/<image>:latest \
  -t sysnet4admin/<image>:<base-version> \
  --push .
```

빌더가 없으면 한 번만 만든다.

```bash
docker buildx create --name multiarch --driver docker-container --use
```

## 2. 태그는 `latest` + 베이스 이미지 버전

`FROM`의 태그에서 뽑는다.

```
FROM nginx:1.26.0-alpine-slim  ->  :latest, :1.26.0
FROM alpine:3.20               ->  :latest, :3.20
```

`LABEL Version`은 이미지마다 의미가 달라(도구 버전, 자체 버전, 실습 라벨) 태그 근거로 쓰지 않는다.

### 예외: 책이 이미 참조 중인 태그

아래는 책 원고와 실습 야믈에 인쇄된 태그다. **절대 삭제하거나 의미를 바꾸지 말 것.**
재빌드할 때 같은 태그로 덮어써야 원고 수정이 필요 없다.

| 이미지 | 유지할 태그 | 참조처 |
|---|---|---|
| `kustomize` | `5.4.1` (kustomize 도구 버전, 베이스 alpine 버전 아님) | ch5/5.4.3 Jenkinsfile |
| `nginx-status` | `latest` | ch6/6.2.3 야믈 2개 |
| `echo-ip`, `echo-hname`, `audit-trail`, `hpa-cpu-memory` | `latest` | ch3, ch4 전반 |
| `dashboard` | `blue`, `green`, `canary-v1` | ch5/5.4.3, ch7/7.4 |

## 3. Dockerfile에 아키텍처를 하드코딩하지 않는다

바이너리를 내려받는다면 buildx가 채우는 `TARGETARCH`를 쓴다.

```dockerfile
ARG TARGETARCH
RUN wget "https://.../tool_linux_${TARGETARCH}.tar.gz"
```

`amd64`를 박아두면 **manifest는 멀티 플랫폼인데 arm64 이미지 안에 amd64 바이너리가 들어간다.**
`docker buildx imagetools inspect`로는 정상으로 보이고, arm64 쿠버네티스 파드에서만
`exec format error`로 터진다.

맥에서 `docker run`으로 테스트하면 Rosetta가 대신 실행해 **문제가 안 드러난다.**
반드시 에뮬레이션이 없는 환경(arm64 리눅스 노드의 containerd)에서 확인한다.

## 4. 푸시 후 검증

manifest 확인만으로는 3번 유형의 결함을 못 잡는다. 실제 바이너리를 본다.

```bash
for P in amd64 arm64; do
  docker run --rm --platform linux/$P --entrypoint sh sysnet4admin/<image>:latest -c '
    for f in $(find /bin /sbin /usr/bin /usr/sbin /usr/local/bin -maxdepth 1 -type f); do
      head -c4 "$f" 2>/dev/null | grep -q ELF || continue
      m=$(od -An -tx1 -j18 -N2 "$f" | tr -d " ")
      echo "$(basename $f) $m"
    done' | sort -u -k2
done
```

ELF `e_machine` 값은 `3e00`이 x86-64, `b700`이 AArch64다.
`linux/arm64`로 받았는데 `3e00`이 섞여 있으면 3번 유형의 결함이다.

## 5. 태그를 덮어썼다면 캐시를 지운다

파드 스펙에 `imagePullPolicy`가 없고 태그가 `latest`가 아니면 기본값이 `IfNotPresent`다.
같은 태그로 덮어써도 **이미 받아둔 노드는 옛 이미지를 계속 쓴다.**

```bash
crictl rmi docker.io/sysnet4admin/<image>:<tag>   # 쿠버네티스 노드
docker rmi sysnet4admin/<image>:<tag>             # 도커 호스트
```

## 참고: 이 규약이 생긴 경위 (2026-08-08)

- **`kustomize:5.4.1`** — manifest는 amd64/arm64 둘 다 있었으나 Dockerfile이
  `kustomize_v5.4.1_linux_amd64.tar.gz`를 하드코딩해 arm64 이미지 안에 amd64 바이너리가 들어감.
  ch5/5.4.3 블루그린 실습이 맥에서 실패. `ARG TARGETARCH`로 수정 후 재빌드.
- **`nginx-status:latest`** — 2021-01-09 푸시된 amd64 단일 이미지로 manifest list 자체가 없었음.
  arm64 노드에서 파드가 뜨지 않음. 저장소에 Dockerfile이 없어 기존 이미지의 빌드 히스토리에서
  역공학해 복원하고 멀티 플랫폼으로 재빌드.

두 건 모두 `docker buildx imagetools inspect`의 platform 목록만 보고 "정상"으로 넘길 뻔했다.
