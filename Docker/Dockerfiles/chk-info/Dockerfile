FROM nginx:stable

LABEL Name=chk-info Version=0.0.9

RUN rm -rf /etc/nginx/conf.d/default.conf
COPY app.conf /etc/nginx/conf.d/
COPY index.html /usr/share/nginx/html 

COPY cert.crt /etc/nginx/conf.d/cert.crt
COPY cert.key /etc/nginx/conf.d/cert.key

CMD ["nginx", "-g", "daemon off;"]
