# http-echo

A tiny, vendor-neutral HTTP echo backend for demos (Gateway API, Ingress, routing labs).
Returns a fixed text over HTTP; the text and port are configurable via env, so the same
image is reusable across talks and labs. Built on `nginx:*-alpine-slim`, multi-arch
(`linux/amd64`, `linux/arm64`).

Published as `sysnet4admin/http-echo`.

## Why

Replaces `hashicorp/http-echo` in demos. That image is genuinely open source (MPL 2.0),
but it carries the HashiCorp/BSL brand association, which is best avoided on a vendor-neutral
CNCF stage. This image is our own, plain nginx, and self-contained.

## Usage

```bash
docker run --rm -e ECHO_TEXT="hello from Gateway API demo" -p 8080:80 sysnet4admin/http-echo
curl localhost:8080            # -> hello from Gateway API demo
```

In Kubernetes:

```yaml
containers:
  - name: echo
    image: sysnet4admin/http-echo:1.0
    env:
      - name: ECHO_TEXT
        value: "hello from Gateway API demo"
    ports:
      - containerPort: 80
```

| Env | Default | Meaning |
|---|---|---|
| `ECHO_TEXT` | `hello from http-echo` | Response body served at every path |
| `ECHO_PORT` | `80` | Listen port |

## Build (no Docker Desktop required)

Multi-arch build needs `docker buildx`. Any of these works; you do **not** need Docker Desktop.

### Option A — a host that already has docker + buildx

```bash
docker login -u sysnet4admin
bash build.sh            # builds linux/amd64,linux/arm64 and pushes :1.0 + :latest
```

`build.sh --load` builds for the local arch only and loads it for quick local testing.

On a plain Linux host without the buildx plugin, install it once:
`docker-buildx` package (distro), or drop the buildx binary into `~/.docker/cli-plugins/`.
`colima` users: `colima start` then buildx is available.

### Option B — GitHub Actions (fully in the cloud, nothing local)

Use `docker/setup-qemu-action` + `docker/setup-buildx-action` + `docker/build-push-action`
with `platforms: linux/amd64,linux/arm64`. Store a Docker Hub access token as a repo secret
(`DOCKERHUB_TOKEN`) and push on demand. Ask and a workflow can be added under `.github/workflows/`.

## Verify a pushed image

```bash
docker buildx imagetools inspect sysnet4admin/http-echo:1.0   # should list amd64 + arm64
```

## Files

| File | Purpose |
|---|---|
| `Dockerfile` | nginx-alpine-slim + env-driven entrypoint |
| `10-render-echo.sh` | renders body/config from `ECHO_TEXT` / `ECHO_PORT` at startup |
| `build.sh` | multi-arch buildx build + push helper |
