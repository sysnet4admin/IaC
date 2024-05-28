FROM nginx:stable

LABEL NAME=test-hpa Version=0.0.1
COPY nginx.conf /etc/nginx/nginx.conf
COPY run.sh /run.sh
EXPOSE 80

ENTRYPOINT ["/run.sh"]
