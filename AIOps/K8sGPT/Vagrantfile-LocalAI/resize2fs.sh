#!/usr/bin/env bash

# avoid 'dpkg-reconfigure: unable to re-open stdin: No file or directory'
export DEBIAN_FRONTEND=noninteractive

#root@w1-k8s:~# parted /dev/sda ---pretend-input-tty resizepart 2 215GB
#Warning: Not all of the space available to /dev/sda appears to be used, you can fix the GPT to use all of the space (an extra 335544320 blocks) or continue with the current setting? 
#Fix/Ignore? Fix                                                           
#Partition number? 2                                                       
#Warning: Partition /dev/sda2 is being used. Are you sure you want to continue?
#Yes/No? yes                                                               
#End?  [42.9GB]? 215GB                                                     
#Information: You may need to update /etc/fstab

parted /dev/sda ---pretend-input-tty <<EOF
resizepart
Fix
2
Yes
215GB
quit
EOF


#echo yes | parted /dev/sda ---pretend-input-tty resizepart 2 215GB
resize2fs /dev/sda2

#https://www.privex.io/articles/how-to-resize-partition/
