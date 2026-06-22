# sysnet4admin/http-echo
# A tiny, vendor-neutral HTTP echo backend for demos (e.g. Gateway API / Ingress).
# Returns a fixed text over HTTP. The response text and port are configurable via env,
# so the same image is reusable across talks and labs.
#
#   docker run -e ECHO_TEXT="hello from Gateway API demo" -p 8080:80 sysnet4admin/http-echo
#   curl localhost:8080   # -> hello from Gateway API demo
#
# Multi-arch (linux/amd64, linux/arm64) — build with buildx (see build.sh / README.md).
FROM nginx:1.27.3-alpine-slim

LABEL Name=http-echo Version=1.0

# Response text and listen port (overridable at `docker run` / Pod spec).
ENV ECHO_TEXT="hello from http-echo" \
    ECHO_PORT=80

# Remove the stock site; our config is rendered at startup from the env vars.
RUN rm -f /etc/nginx/conf.d/default.conf

# The official nginx image runs every /docker-entrypoint.d/*.sh before starting nginx,
# so this renders the response/config from ECHO_TEXT / ECHO_PORT on each container start.
COPY 10-render-echo.sh /docker-entrypoint.d/10-render-echo.sh
RUN chmod +x /docker-entrypoint.d/10-render-echo.sh

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
