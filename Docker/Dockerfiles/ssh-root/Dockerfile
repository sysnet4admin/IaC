FROM alpine:3.13.5

LABEL Name=ssh-root Version=3.13.5

RUN set -x \
&& apk add --no-cache openssh bash tzdata openntpd bind-tools curl \
&& sed 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' -i /etc/ssh/sshd_config \
&& echo 'root:vagrant' | chpasswd \
&& ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa \
&& ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa \
&& mkdir -p /var/run/sshd \
&& ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime 

ENV HOSTNAME ssh-root 
COPY bashrc /root/.bashrc

EXPOSE 22
CMD ["/usr/sbin/sshd","-D"]
