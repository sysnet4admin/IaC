# Harbor arm64 Image Builder

Harbor v2.15.x 공식 이미지는 linux/amd64 전용입니다. 이 스크립트는 arm64 환경(Apple Silicon)을 위한 Harbor 컴포넌트 이미지를 빌드하고 DockerHub에 푸시합니다.

## 배경

- Harbor PR #22311 (Full Multi-Architecture Enablement) — v2.16 예정
- v2.15.x 이하 전 버전: amd64 전용, arm64 미지원
- 책 실습 환경이 arm64(Apple Silicon + VirtualBox)를 지원하므로 직접 빌드 필요

## 빌드 대상 이미지

| 이미지 | 태그 |
|---|---|
| sysnet4admin/prepare | v2.15.0-arm64 |
| sysnet4admin/harbor-core | v2.15.0-arm64 |
| sysnet4admin/harbor-portal | v2.15.0-arm64 |
| sysnet4admin/harbor-db | v2.15.0-arm64 |
| sysnet4admin/harbor-registryctl | v2.15.0-arm64 |
| sysnet4admin/harbor-log | v2.15.0-arm64 |
| sysnet4admin/harbor-jobservice | v2.15.0-arm64 |
| sysnet4admin/harbor-exporter | v2.15.0-arm64 |
| sysnet4admin/registry-photon | v2.15.0-arm64 |
| sysnet4admin/nginx-photon | v2.15.0-arm64 |
| sysnet4admin/redis-photon | v2.15.0-arm64 |

## 사전 조건

- arm64 호스트 (Apple Silicon Mac 또는 arm64 Linux)
- `docker login` (sysnet4admin 계정)
- 여유 디스크 20GB 이상, 안정적인 인터넷 연결

## 사용법

```bash
bash build.sh          # 빌드 + DockerHub 푸시
bash build.sh --build  # 빌드만 (푸시 없음)
bash build.sh --push   # 푸시만 (이미 빌드된 경우)
```

## 빌드 과정

1. Harbor v2.15.0 소스 클론 (`harbor-src/`)
2. `make/photon/exporter/Dockerfile` 패치 (`ENV GOARCH=amd64` 제거)
3. `make compile` — swagger 코드 생성 + Go 바이너리 컴파일 (Docker 컨테이너 내)
4. `make build` — 11개 컴포넌트 이미지 빌드
5. DockerHub 푸시

## 참고

- `_Book_k8sInfra/ch4/4.4.2/2.harbor/2-1.get_harbor.sh` — arm64 감지 시 prepare 이미지를 sysnet4admin으로 자동 교체
- arm64 prepare 이미지가 `IMAGENAMESPACE=sysnet4admin`, `VERSIONTAG=v2.15.0-arm64`로 빌드되어 있어 docker-compose.yml도 올바른 이미지명으로 자동 생성됨
