FROM nginx:1.26.0-alpine-slim

LABEL Name=tardy-nginx Version=1.26.0

COPY startup.sh /
RUN chmod +x /startup.sh 
CMD ["/startup.sh"]
RUN echo "tardy again" > /usr/share/nginx/html/index.html 

RUN ln -sf /proc/1/fd/1 /var/log/sleep.log 

