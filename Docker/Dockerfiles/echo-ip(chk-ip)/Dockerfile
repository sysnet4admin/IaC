FROM nginx:1.26.0-alpine-slim

LABEL Name=echo-ip(chk-ip) Version=1.26.0

COPY nginx.conf /etc/nginx/nginx.conf
COPY cert.crt /etc/nginx/conf.d/cert.crt
COPY cert.key /etc/nginx/conf.d/cert.key

CMD ["nginx", "-g", "daemon off;"]
