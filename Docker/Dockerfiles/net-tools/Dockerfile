FROM curlimages/curl:7.76.1

LABEL Name=net-tools Version=1.0.0

USER root
RUN apk add --no-cache bash

ENV HOSTNAME net-tools
COPY bashrc /root/.bashrc
COPY curlchk /usr/local/bin/curlchk

# forward request and error for curl logs to docker log collector
RUN ln -sf /proc/1/fd/1 /var/log/curl.log


