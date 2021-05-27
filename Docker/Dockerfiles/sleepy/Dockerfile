FROM alpine:3.13.5

LABEL Name=sleepy Version=3.13.5

USER root
RUN apk add --no-cache bash tzdata openntpd
RUN ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

ENV HOSTNAME sleepy
COPY bashrc /root/.bashrc

ENTRYPOINT ["sleep", "infinity"]





