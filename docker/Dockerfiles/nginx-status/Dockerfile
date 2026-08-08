FROM nginx:1.26.0-alpine-slim

LABEL Name=nginx-status Version=1.26.0

RUN apk add --no-cache bash 

COPY default.conf /etc/nginx/conf.d/default.conf

CMD ["nginx", "-g", "daemon off;"]
