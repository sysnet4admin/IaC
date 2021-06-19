#!/usr/bin/env bash
sleep 1 && echo "deep sleep" > /var/log/sleep.log
sleep 59
nginx -g "daemon off;" 
