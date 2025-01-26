FROM nginx:1.27.3-alpine-slim

LABEL Name=kubecon-eu Version=latest

RUN apk add --no-cache bash \ 
    && rm -rf /etc/nginx/conf.d/default.conf

COPY app.conf /etc/nginx/conf.d/
COPY index.html /usr/share/nginx/html 

COPY cert.crt /etc/nginx/conf.d/cert.crt
COPY cert.key /etc/nginx/conf.d/cert.key

CMD ["nginx", "-g", "daemon off;"]

