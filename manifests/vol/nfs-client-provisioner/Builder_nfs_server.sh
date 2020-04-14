mkdir /nfs_shared
echo '/nfs_shared 192.168.1.0/24(rw,sync,no_root_squash)'  >> /etc/exports
systemctl enable --now nfs