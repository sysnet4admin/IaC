#!/bin/sh
# Render the echo response and nginx server block from environment variables.
# Runs via the nginx base image's /docker-entrypoint.d hook before nginx starts.
set -eu

: "${ECHO_TEXT:=hello from http-echo}"
: "${ECHO_PORT:=80}"

# Body served at every path. printf gives a trailing newline (clean curl output).
printf '%s\n' "$ECHO_TEXT" > /usr/share/nginx/html/index.html

# Plain-text server on $ECHO_PORT; any path returns the body.
cat > /etc/nginx/conf.d/echo.conf <<EOF
server {
    listen ${ECHO_PORT} default_server;
    server_name _;
    root /usr/share/nginx/html;
    charset utf-8;
    default_type text/plain;
    location / {
        types { }
        default_type text/plain;
        try_files /index.html =404;
    }
}
EOF
