#!/usr/bin/env bash
spawn-fcgi -p 9001 -P /run/spawn-fcgi.pid -- /usr/sbin/fcgiwrap -c 3;
./docker-entrypoint.sh nginx;
