# Bento's source
https://github.com/chef/bento

# Run
```bash
cd bento 
bento build --cpus 4 --only=vmware-iso.vm os_pkrvars/ubuntu/ubuntu-22.04-aarch64.pkrvars.hcl
```

# Run & Move
```bash
cd bento 
bento build --cpus 4 --only=vmware-iso.vm os_pkrvars/ubuntu/ubuntu-22.04-aarch64.pkrvars.hcl \ 
; mv builds/ubuntu-22.04-aarch64.virtualbox.box ~/Documents/vagrant_cloud
```

# Dry-run
```bash
cd bento 
 bento build --cpus 4 --dry-run --only=vmware-iso.vm os_pkrvars/ubuntu/ubuntu-22.04-aarch64.pkrvars.hcl
```

# Modified
- ubuntu-22.04-aarch64.pkrvars.hcl in local iso 
+ pkr-builder.pkr.hcl
  - custom_pre_hoon.sh
  - custom_post_hoon.sh

