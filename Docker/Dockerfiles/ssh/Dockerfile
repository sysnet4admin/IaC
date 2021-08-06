FROM ubuntu:21.10

ARG DEBIAN_FRONTEND=noninteractive 
ENV USER hoon 
 
ENV TZ=Asia/Seoul
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN sed -i'' 's/archive\.ubuntu\.com/us\.archive\.ubuntu\.com/' /etc/apt/sources.list
 
RUN apt-get update
RUN apt-get install -y ssh openssh-server vim sudo
RUN mkdir /var/run/sshd
 
#replace sshd_config
RUN sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
 
#set sudo for $USER
RUN sed -ri '20a'$USER'    ALL=(ALL) NOPASSWD:ALL' /etc/sudoers
 
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
 
#make .ssh
RUN useradd -m $USER
RUN mkdir /home/$USER/.ssh
RUN chown $USER.$USER /home/$USER/.ssh
RUN chmod 700 /home/$USER/.ssh
 
#change shell 
RUN ln -sf /bin/bash /bin/sh
 
#set password
RUN echo $USER':hoon' |chpasswd
 
EXPOSE 22
EXPOSE 80
EXPOSE 443
 
CMD ["/usr/sbin/sshd", "-D"]

