> 📦 **원본(Source):** https://github.com/k8s-edu/Bkv2_sub_dashboard
> · branch: `canary` · snapshot: `f11a558`

## 대시보드 앱

이 저장소는 컨테이너 인프라 환경 구축을 위한 쿠버네티스/도커 책 실습 부분에서 예제로 배포되는 애플리케이션입니다. 애플리케이션은 Next.js를 사용하여 작성하였으며, 카나리 배포 실습 과정에 대시보드의 변경을 체험하기 위한 두 가지 버전이 존재합니다. `v1` 버전은 기존 대시보드의 모습을 유지하는 버전이며, `v2` 버전은 대시보드의 UI가 변경된 버전입니다. 책에서는 `v1` 버전을 먼저 배포한 후, `v2` 버전을 배포하여 카나리 배포 실습을 진행합니다.

Note: 이 애플리케이션을 단일로 구성하기 위해서는 Node.js 18 버전 이상이 필요합니다.

# 로컬 개발환경
```bash
npm i
npm run dev
```

## 컨테이너 이미지 빌드 방법
```shell
docker build -t <이미지 태그> --build-arg=PHASE=[v1|v2]
# 예시 블루
docker build -t dashboard:canary-v1 --build-arg=PHASE=v1 .
# 예시 그린
docker build -t dashboard:canary-v2 --build-arg=PHASE=v2 .
```

카나리 대시보드는 특정 시점에 따라서, 다른 레포지토리 통합되거나 업데이트 될 수 있습니다.

---

## 멀티플랫폼 빌드 관리 (IaC 로컬 복사본)

원본: https://github.com/k8s-edu/Bkv2_sub_dashboard (branch: `canary`)

이 디렉터리는 위 저장소 `canary` 브랜치의 복사본이며, `Makefile` 로 멀티플랫폼(amd64/arm64) 이미지를 빌드·푸시합니다.
대상 이미지: `sysnet4admin/dashboard:canary-v1`, `sysnet4admin/dashboard:canary-v2`

```bash
make builder   # (최초 1회) multiarch buildx 빌더 생성
make login     # docker hub 로그인
make v1        # canary-v1 (amd64+arm64) 빌드 & 푸시
make v2        # canary-v2 (amd64+arm64) 빌드 & 푸시
make all       # v1, v2 모두

# 변수 오버라이드 예시
make all IMAGE=myrepo/dashboard PLATFORMS=linux/amd64,linux/arm64
```

> 멀티아치 이미지는 로컬 docker로 `--load` 할 수 없어 `--push`(레지스트리 푸시)로 동작합니다.
