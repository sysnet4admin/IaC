#!/usr/bin/env bash

echo "deep sleep" > /var/log/sleep.log && sleep 60
touch /tmp/healthy-on && nginx -g "daemon off;" 
