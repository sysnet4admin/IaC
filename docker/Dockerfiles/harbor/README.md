# Harbor arm64 Image Builder

Harbor 공식 이미지는 v2.15.x 이하 전 버전이 linux/amd64 전용입니다. 이 스크립트는 arm64 환경(Apple Silicon)을 위한 Harbor 컴포넌트 이미지를 빌드하고 DockerHub에 푸시합니다.

**기본 빌드 버전은 v2.10.0**입니다. 원고 버전 변경 최소화 정책(`_prepublish_updates/misc.md`)에 따라 원고에 쓰인 v2.10.0으로 확정했습니다. v2.15.0 등 다른 버전은 `HARBOR_VERSION` 환경변수로 오버라이드해 빌드합니다.

## 배경

- Harbor PR #22311 (Full Multi-Architecture Enablement) — v2.16 정식 지원 예정 (2026년 9월)
- v2.15.x 이하 전 버전: amd64 전용, arm64 미지원
- 책 실습 환경이 arm64(Apple Silicon + VirtualBox)를 지원하므로 직접 빌드 필요

## 빌드 대상 이미지

11개 컴포넌트를 `sysnet4admin/<이미지>:<버전>-arm64` 태그로 빌드합니다. (예: 기본값 v2.10.0이면 `-arm64` 태그가 `v2.10.0-arm64`)

| 이미지 | 태그 (기본) |
|---|---|
| sysnet4admin/prepare | v2.10.0-arm64 |
| sysnet4admin/harbor-core | v2.10.0-arm64 |
| sysnet4admin/harbor-portal | v2.10.0-arm64 |
| sysnet4admin/harbor-db | v2.10.0-arm64 |
| sysnet4admin/harbor-registryctl | v2.10.0-arm64 |
| sysnet4admin/harbor-log | v2.10.0-arm64 |
| sysnet4admin/harbor-jobservice | v2.10.0-arm64 |
| sysnet4admin/harbor-exporter | v2.10.0-arm64 |
| sysnet4admin/registry-photon | v2.10.0-arm64 |
| sysnet4admin/nginx-photon | v2.10.0-arm64 |
| sysnet4admin/redis-photon | v2.10.0-arm64 |

## 사전 조건

- arm64 호스트 (Apple Silicon Mac 또는 arm64 Linux)
- `docker login` (sysnet4admin 계정)
- 여유 디스크 20GB 이상, 안정적인 인터넷 연결

## 사용법

```bash
bash build.sh                          # 빌드 + DockerHub 푸시 (기본 v2.10.0)
bash build.sh --build                  # 빌드만 (푸시 없음)
bash build.sh --push                   # 푸시만 (이미 빌드된 경우)
HARBOR_VERSION=v2.15.0 bash build.sh   # 다른 버전 빌드
```

## 빌드 과정

1. Harbor 소스 클론 (`harbor-src-<버전>/`)
2. `make/photon/exporter/Dockerfile` 패치 (`ENV GOARCH=amd64` → `arm64`)
3. `make compile` — swagger 코드 생성 + Go 바이너리 컴파일 (Docker 컨테이너 내)
4. `make build` — 11개 컴포넌트 이미지 빌드
5. DockerHub 푸시

## 참고

- `_Book_k8sInfra/ch4/4.4.2/2.harbor/2-1.get_harbor.sh` — arm64 감지 시 prepare 이미지를 sysnet4admin으로 교체하고, 생성된 `docker-compose.yml`의 네임스페이스(`goharbor/` → `sysnet4admin/`)를 sed로 치환.
- prepare 이미지가 태그(`<버전>-arm64`)는 올바르게 굽지만 네임스페이스는 upstream 템플릿에 `goharbor/`로 하드코딩되어 있어, `2-1.get_harbor.sh`에서 네임스페이스 sed 치환이 반드시 필요함. **태그 sed는 넣지 말 것** (이중 태그 `-arm64-arm64` 버그).
- **검증은 이미지 캐시 없는 클린 arm64 환경**에서 할 것. 빌드 머신은 로컬에 `goharbor/*:<버전>-arm64` 캐시가 남아 pull 실패를 가림.
