#!/bin/sh -eux

# add google dns server to avoid dns query error 
cat <<EOF >/etc/resolv.conf
nameserver 8.8.8.8
EOF

