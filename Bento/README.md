# Bento's source 
https://github.com/chef/bento

# Run 
```bash 
bento build --cpus 4 --only=vmware-iso.vm os_pkrvars/ubuntu/ubuntu-22.04-aarch64.pkrvars.hcl
```

# Dry-run
```bash
 bento build --cpus 4 --dry-run --only=vmware-iso.vm os_pkrvars/ubuntu/ubuntu-22.04-aarch64.pkrvars.hcl
```

# Modified 
- ubuntu-22.04-aarch64.pkrvars.hcl
- networking_ubuntu.sh
- sudoers_ubuntu.sh
