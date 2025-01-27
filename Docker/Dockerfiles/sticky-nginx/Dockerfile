FROM nginx:1.27.3-alpine-slim

LABEL Name=sticky-nginx Version=${NGINX_VERSION}

RUN apk add --no-cache bash 

COPY nginx.conf /etc/nginx/nginx.conf
COPY cert.crt /etc/nginx/conf.d/cert.crt
COPY cert.key /etc/nginx/conf.d/cert.key

CMD ["nginx", "-g", "daemon off;"]
