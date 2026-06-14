> 📦 **원본(Source):** https://github.com/k8s-edu/Bkv2_sub_dashboard
> · branch: `main` · snapshot: `ff6254c`

## 대시보드 앱

이 저장소는 컨테이너 인프라 환경 구축을 위한 쿠버네티스/도커 책 실습 부분에서 예제로 배포되는 애플리케이션입니다. 애플리케이션은 Next.js를 사용하여 작성하였으며, 사용자의 활동을 히트맵 형식의 그래프로 보여주는 기능을 제공합니다.

Note: 이 애플리케이션을 단일로 구성하기 위해서는 Node.js 18 버전 이상이 필요합니다.

# 로컬 개발환경
```bash
npm i
npm run dev
```

## 컨테이너 이미지 빌드 방법
```shell
docker build -t <이미지 태그> --build-arg=PHASE=[blue|green]
# 예시 블루
docker build -t dashboard:blue --build-arg=PHASE=blue .
# 예시 그린
docker build -t dashboard:green --build-arg=PHASE=green .
```

---

## 멀티플랫폼 빌드 관리 (IaC 로컬 복사본)

원본: https://github.com/k8s-edu/Bkv2_sub_dashboard (branch: `main`)

이 디렉터리는 위 저장소 `main` 브랜치의 복사본이며, `Makefile` 로 멀티플랫폼(amd64/arm64) 이미지를 빌드·푸시합니다.
대상 이미지: `sysnet4admin/dashboard:blue`, `sysnet4admin/dashboard:green`

```bash
make builder   # (최초 1회) multiarch buildx 빌더 생성
make login     # docker hub 로그인
make blue      # blue (amd64+arm64) 빌드 & 푸시
make green     # green (amd64+arm64) 빌드 & 푸시
make all       # blue, green 모두

# 변수 오버라이드 예시
make all IMAGE=myrepo/dashboard PLATFORMS=linux/amd64,linux/arm64
```

> 멀티아치 이미지는 로컬 docker로 `--load` 할 수 없어 `--push`(레지스트리 푸시)로 동작합니다.
