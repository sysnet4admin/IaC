FROM alpine:3.13.5

LABEL Name=k8s-checker Version=3.13.5

USER root
RUN apk add --no-cache bash tzdata openntpd bind-tools curl
RUN ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

ENV HOSTNAME k8s-checker
COPY bashrc /root/.bashrc
COPY curlchk-insec /usr/local/bin/curlchk-insec
RUN chmod 700 /usr/local/bin/curlchk-insec 

# forward request and error for curl logs to docker log collector
RUN ln -sf /proc/1/fd/1 /var/log/curl.log
RUN curlchk-insec "https://kubernetes.default.svc.cluster.local/healthz"

