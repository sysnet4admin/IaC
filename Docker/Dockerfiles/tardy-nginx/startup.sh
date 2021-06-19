#!/usr/bin/env bash

echo "deep sleep" > /var/log/sleep.log && sleep 60
nginx -g "daemon off;" 
