FROM alpine:3.20
LABEL Name=KUSTOMIZE Version=5.4.1
WORKDIR /tmp
RUN set -ex; wget "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.4.1/kustomize_v5.4.1_linux_amd64.tar.gz" \
    && tar -xvf  kustomize_v5.4.1_linux_amd64.tar.gz \
    && chmod 744 kustomize \
    && cp kustomize /bin/kustomize