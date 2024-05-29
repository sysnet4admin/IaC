FROM nginx:1.26.0-alpine-slim

LABEL NAME=hpa-cpu-memory Version=1.26.0

COPY nginx.conf /etc/nginx/nginx.conf
COPY run.sh /run.sh

EXPOSE 80

ENTRYPOINT ["/run.sh"]
