
# Switch base-img 
ARG BASE_IMAGE=nginx:1.27.3-alpine-slim
#ARG BASE_IMAGE=nginx:1.26.0-alpine-slim

FROM ${BASE_IMAGE} 

LABEL Name=kubecon-eu Version=${NGINX_VERSION}

RUN apk add --no-cache bash                         \ 
    && rm -rf /etc/nginx/conf.d/default.conf        \
    && echo "Nginx Version is ${NGINX_VERSION}" > /usr/share/nginx/html/index.html 

COPY app.conf /etc/nginx/conf.d/
COPY cert.crt /etc/nginx/conf.d/cert.crt  
COPY cert.key /etc/nginx/conf.d/cert.key

CMD ["nginx", "-g", "daemon off;"]

