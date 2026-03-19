FROM ubuntu:21.10
RUN apt-get update && apt-get install -y \
            supervisor \
            nginx \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord"]
