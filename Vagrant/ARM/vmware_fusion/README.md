# vagrant_vmware


## Vagrant + VMware Fusion
### Install Vmware Fusion
- [Download VMWare Fusion](https://customerconnect.vmware.com/en/evalcenter?p=fusion-player-personal-13)
- Requires sign up to retrieve the license key (personal license)
- Install

### Install vagrant and plugin
```bash
brew install vagrant
brew install vagrant-vmware-utility
```

### Run utility
```bash
sudo launchctl load -w /Library/LaunchDaemons/com.vagrant.vagrant-vmware-utility.plist
```
### Install Plugin
```bash
vagrant plugin install vagrant-vmware-desktop
```

### Verification
```bash
vagrant --version
vagrant plugin list
```


### Add this to wherever matches the subnet

```bash
sudo /Applications/VMware\ Fusion.app/Contents/Library/vmnet-cfgcli vnetcfgadd VNET_8_HOSTONLY_SUBNET 192.168.1.0
sudo /Applications/VMware\ Fusion.app/Contents/Library/vmnet-cfgcli vnetcfgadd VNET_8_DHCP yes
sudo /Applications/VMware\ Fusion.app/Contents/Library/vmnet-cfgcli vnetcfgadd VNET_8_NAT yes
sudo /Applications/VMware\ Fusion.app/Contents/Library/vmnet-cfgcli vnetcfgadd VNET_8_VIRTUAL_ADAPTER yes

sudo /Applications/VMware\ Fusion.app/Contents/Library/vmnet-cli --configure
sudo /Applications/VMware\ Fusion.app/Contents/Library/vmnet-cli --stop
sudo /Applications/VMware\ Fusion.app/Contents/Library/vmnet-cli --start
```


### Execution
```bash
vagrant up --provider vmware-fusion
```


### Termination
```bash
# force flag will purge out ssh key info
vagrant destroy --force
```
