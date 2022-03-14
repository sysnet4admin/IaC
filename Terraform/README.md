테라폼을 3사에 사용하려고 만들었습니다. kubeflow도 해야 하고...매번 만들긴 귀찮고 해서... 
주로 44bit의 블로그([Terraform](https://www.44bits.io/ko/post/terraform_introduction_infrastrucute_as_code), [direnv](https://www.44bits.io/ko/post/direnv_for_managing_directory_environment))를 참조 하였습니다. 
- Terraform: `1.1.7`
- tfenv: latest
- direnv: latest
- tfenv: latest

참고로 윈도우에서 tfenv를 하려면 [다음](https://dev.to/lkurzyniec/terraform-version-switcher-for-windows-42c4)을 참고하세요. 

## 사용법
```bash
$ vagrant up
Bringing machine 't7m-Console' up with 'virtualbox' provider...
==> t7m-Console: Importing base box 'sysnet4admin/Ubuntu-k8s'...
==> t7m-Console: Matching MAC address for NAT networking...
<snipped>
```
끝나면, ~/t7m 아래에 다음과 같이 3사 CSP가 위치해 있습니다. 
그리고 각각 디렉터리 밑에 .envrc 예제가 들어 있습니다. 이를 적당히 수정해서 사용하면 됩니다.  
```bash 
root@t7m-Console:~/t7m# ls -rlt
total 12
drwxr-xr-x 3 root root 4096 Mar 14 07:14 azurerm
drwxr-xr-x 3 root root 4096 Mar 14 07:14 google
drwxr-xr-x 3 root root 4096 Mar 14 07:15 aws
```
