FROM alpine:3.13.5

LABEL Name=net-tools Version=3.13.5

USER root
RUN apk add --no-cache bash tzdata openntpd bind-tools curl
RUN ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

ENV HOSTNAME net-tools
COPY bashrc /root/.bashrc
COPY curlchk /usr/local/bin/curlchk ; curlchk-k /usr/local/bin/curlchk-k
RUN chmod 700 /usr/local/bin/curlchk ; chmod 700 /usr/local/bin/curlchk-k 

# forward request and error for curl logs to docker log collector
RUN ln -sf /proc/1/fd/1 /var/log/curl.log

