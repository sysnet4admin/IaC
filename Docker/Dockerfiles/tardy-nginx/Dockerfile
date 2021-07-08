FROM nginx:1.20.1

LABEL Name=tardy-nginx Version=1.20.1

COPY startup.sh /
RUN chmod +x /startup.sh 
CMD ["/startup.sh"]
RUN echo "tardy again" > /usr/share/nginx/html/index.html 

RUN ln -sf /proc/1/fd/1 /var/log/sleep.log 

