FROM nginx:1.26.0-alpine-slim

LABEL Name=chk-info Version=1.26.0

RUN rm -rf /etc/nginx/conf.d/default.conf
COPY app.conf /etc/nginx/conf.d/
COPY index.html /usr/share/nginx/html 

COPY cert.crt /etc/nginx/conf.d/cert.crt
COPY cert.key /etc/nginx/conf.d/cert.key

CMD ["nginx", "-g", "daemon off;"]
