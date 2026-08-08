FROM alpine:3.20

# buildx sets TARGETARCH to amd64/arm64, matching the kustomize release
# asset naming (kustomize_v5.4.1_linux_${ARCH}.tar.gz). Do not hardcode the
# arch here — a multi-platform manifest built from a hardcoded amd64 tarball
# ships an amd64 binary inside the arm64 image, which fails with
# "exec format error" on arm64 nodes.
ARG TARGETARCH

LABEL Name=kustomize Version=5.4.1

WORKDIR /tmp
RUN set -ex; wget "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.4.1/kustomize_v5.4.1_linux_${TARGETARCH}.tar.gz" \
    && tar -xvf  kustomize_v5.4.1_linux_${TARGETARCH}.tar.gz \
    && chmod 744 kustomize \
    && cp kustomize /bin/kustomize
