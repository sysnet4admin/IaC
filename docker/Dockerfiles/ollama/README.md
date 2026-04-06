# Ollama Model Dockerfiles

Ollama 기반 LLM 모델을 미리 내장한 커스텀 이미지 Dockerfile 모음입니다.  
이미지 빌드 시 모델을 pull하여 이미지 안에 포함시켜, 배포 후 별도 다운로드 없이 즉시 사용 가능합니다.

## Dockerfile 목록

| 파일 | 베이스 | 내장 모델 | 비고 |
|---|---|---|---|
| `Dockerfile.gemma3` | ollama/ollama:latest | gemma3:270m | _Book_k8sInfra ch7 |
| `Dockerfile.gemma3-4b` | ollama/ollama:latest | gemma3:4b | _Book_k8sInfra ch7 |
| `Dockerfile.llama32` | ollama/ollama:latest | llama3.2:1b | _Book_k8sInfra ch7 |
| `Dockerfile.qwen35` | ollama/ollama:latest | qwen3.5:0.8b | _Book_k8sInfra ch7 |
| `Dockerfile.qwen35-2b` | ollama/ollama:latest | qwen3.5:2b | _Book_k8sInfra ch7 |
| `Dockerfile.qwen35-4b` | ollama/ollama:latest | qwen3.5:4b | _Book_k8sInfra ch7 |
| `Dockerfile.gemma2-2b` | ollama/ollama:0.3.14 | gemma2:2b | 구버전 |
| `Dockerfile.llama32-1b-v0314` | ollama/ollama:0.3.14 | llama3.2:1b | 구버전 |
| `Dockerfile.qwen25-15b` | ollama/ollama:0.3.14 | qwen2.5:1.5b | 구버전 |

## 빌드 예시

```bash
# 단일 이미지 빌드 + 푸시
docker build -f Dockerfile.gemma3 -t sysnet4admin/ollama-gemma3:270m .
docker push sysnet4admin/ollama-gemma3:270m

# 멀티플랫폼 빌드 (buildx)
docker buildx build --platform linux/amd64,linux/arm64 \
  -f Dockerfile.gemma3 -t sysnet4admin/ollama-gemma3:270m --push .
```

## 참고

- `_Book_k8sInfra/ch7/7.5.1/` — 책 실습에서 사용하는 yaml 및 Dockerfile 원본
- ollama:latest 기반 Dockerfile은 `pkill ollama || true`로 serve 프로세스를 종료하여 레이어를 커밋
