FROM nginx:1.26.0-alpine-slim

LABEL Name=audit-trail(chk-log) Version=1.26.0

COPY nginx.conf /etc/nginx/nginx.conf
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log 
RUN cp -f /usr/share/zoneinfo/Asia/Seoul /etc/localtime
RUN mkdir -p /audit

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]
