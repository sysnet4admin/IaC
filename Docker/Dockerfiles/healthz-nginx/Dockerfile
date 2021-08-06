FROM nginx:1.20.1

LABEL Name=healthz-nginx Version=1.20.1

RUN rm -rf /etc/nginx/conf.d/default.conf
COPY app.conf /etc/nginx/conf.d/
COPY healthz /usr/share/nginx/html 

COPY cert.crt /etc/nginx/conf.d/cert.crt
COPY cert.key /etc/nginx/conf.d/cert.key

CMD ["nginx", "-g", "daemon off;"]
