#!/usr/bin/env bash

# avoid 'dpkg-reconfigure: unable to re-open stdin: No file or directory'
export DEBIAN_FRONTEND=noninteractive

# unknown issue for python
mv /usr/local/lib/python3.10/dist-packages/ /usr/local/lib/python3.10/site-packages

# get rubra.ai platform
 curl -sfL https://get.rubra.ai | bash -s -- start

