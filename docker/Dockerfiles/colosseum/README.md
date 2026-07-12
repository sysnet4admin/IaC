# colosseum 마이크로서비스 이미지 빌드

[k8s-edu/Bkv2_sub_colosseum](https://github.com/k8s-edu/Bkv2_sub_colosseum)의 각
마이크로서비스를 멀티아치(amd64+arm64) 이미지로 빌드해서 Docker Hub
`sysnet4admin/colosseum-*`에 푸시한다.

이 서비스들의 Dockerfile은 소스를 컴파일하는 형태(gradle/npm/go/uv)라 Dockerfile만으로는
빌드되지 않는다. 그래서 `build.sh`가 빌드 시점에 upstream을 임시 디렉터리에 clone해서
서비스 폴더별로 빌드한다. 소스는 이 저장소에 복제하지 않는다.

## 이미지 목록

| 이미지 | 서비스 | Dockerfile | 설명 |
|--------|--------|-----------|------|
| `colosseum-agg:log` | agg (Kotlin/Spring) | `Dockerfile.log` | 기본 |
| `colosseum-agg:trace` | agg | `Dockerfile.trace` | + OpenTelemetry javaagent |
| `colosseum-agg:profile` | agg | `Dockerfile.profile` | + OpenTelemetry + Pyroscope |
| `colosseum-cms:log` | cms (Node/NestJS) | `Dockerfile` | 기본(log) |
| `colosseum-nti:log` | nti (Go) | `Dockerfile` | multi-stage, alpine |
| `colosseum-prm:log` | prm (Node/NestJS) | `Dockerfile` | |
| `colosseum-rwd:log` | rwd (Python/uv) | `Dockerfile` | uvicorn |

`log`이 모든 서비스의 기본 태그다. agg만 추가로 `trace`/`profile` 변형을 갖는다.

## Docker Hub 이미지

모두 멀티아치(linux/amd64 + linux/arm64)로 `sysnet4admin`에 푸시된다.

```
sysnet4admin/colosseum-agg:log
sysnet4admin/colosseum-agg:trace
sysnet4admin/colosseum-agg:profile
sysnet4admin/colosseum-cms:log
sysnet4admin/colosseum-nti:log
sysnet4admin/colosseum-prm:log
sysnet4admin/colosseum-rwd:log
```

## 사용

```bash
# 전체 빌드/푸시 (Docker Hub 로그인 필요)
./build.sh

# 일부만
./build.sh agg           # agg 3종만
./build.sh cms prm       # cms, prm만

# 실제 빌드 없이 계획만
DRY_RUN=1 ./build.sh
```

## 환경변수

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `REPO` | `https://github.com/k8s-edu/Bkv2_sub_colosseum` | upstream 저장소 |
| `REF` | `main` | 브랜치/태그/커밋. 특정 시점 고정 시 커밋 해시 지정 |
| `NAMESPACE` | `sysnet4admin` | 이미지 네임스페이스 |
| `PLATFORMS` | `linux/amd64,linux/arm64` | 빌드 플랫폼 |
| `BUILDER` | `multiarch` | buildx 빌더(없으면 자동 생성) |
| `PUSH` | `1` | 0이면 push 생략 |

기본은 항상 최신 `main`을 빌드한다. 재현성이 필요하면 `REF=<커밋해시> ./build.sh`로 고정한다.
