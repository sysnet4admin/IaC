### rook ceph lab 

실습을 하기 위해서 필요한 패키지를 종합해 놓음. 
따라서 수시로 업데이트 될 수 있습니다.  

이름              | 버전     |   빈칸 
----            | ----    | ---- 
kubernetes      | v1.32.2 | 
MetalLB         | v0.10.2 | 
nfs-provisioner | 4.0.2   |
Metrics Server  | 0.5.0   |
Kustomize       | 4.2.0   |
Helm            | 3.6.3   |

#### 특이점 
helm 자동 완성 기능을 사용하길 원한다면, 다음의 명령을 수행해야 합니다.  
```bash
sh /tmp/helm_completion.sh
```

#### 배포 후 기본 소모되는 CPU와 Memory  
[root@rc-m-k8s ~]# k top node
NAME           CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
rc-ceph1-k8s   80m          8%     912Mi           48%
rc-ceph2-k8s   142m         14%    1275Mi          67%
rc-ceph3-k8s   112m         11%    962Mi           50%
rc-m-k8s       213m         10%    1357Mi          71%
rc-w1-k8s      64m          6%     989Mi           52%
rc-w2-k8s      63m          6%     988Mi           52%
rc-w3-k8s      85m          8%     913Mi           48%
