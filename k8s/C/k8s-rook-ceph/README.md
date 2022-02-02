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

#### 배포 전/후 기본 소모되는 CPU와 Memory  
```
[root@rc-m-k8s ~]# k top node 
NAME        CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
rc-m-k8s    142m         7%     1261Mi          66%       
rc-s1-k8s   51m          5%     764Mi           66%       
rc-s2-k8s   51m          5%     764Mi           66%       
rc-s3-k8s   51m          5%     764Mi           66%       
rc-w1-k8s   51m          5%     764Mi           54%       
rc-w2-k8s   48m          4%     749Mi           53%       
rc-w3-k8s   47m          4%     740Mi           53% 
```
```
[root@rc-m-k8s ~]# k top node 
NAME        CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
rc-m-k8s    166m         8%     1371Mi          72%       
rc-s1-k8s   121m         12%    1152Mi          100%      
rc-s2-k8s   121m         12%    1152Mi          100%      
rc-s3-k8s   121m         12%    1152Mi          100%      
rc-w1-k8s   121m         12%    1152Mi          82%       
rc-w2-k8s   94m          9%     803Mi           57%       
rc-w3-k8s   55m          5%     722Mi           51% 
```

#### 배포 후 rook-ceph 
```
[root@rc-m-k8s ~]# k get po -n rook-ceph 
NAME                                                  READY   STATUS      RESTARTS   AGE
csi-cephfsplugin-2fzv5                                3/3     Running     0          9m35s
csi-cephfsplugin-49ktv                                3/3     Running     0          9m35s
csi-cephfsplugin-7rbtj                                3/3     Running     0          9m36s
csi-cephfsplugin-bzb9z                                3/3     Running     0          9m35s
csi-cephfsplugin-provisioner-b4f7d7bd4-gwv4r          6/6     Running     0          9m35s
csi-cephfsplugin-provisioner-b4f7d7bd4-v8l96          6/6     Running     0          9m35s
csi-cephfsplugin-ssgpj                                3/3     Running     0          9m35s
csi-cephfsplugin-wjxkm                                3/3     Running     0          9m35s
csi-rbdplugin-4rk95                                   3/3     Running     0          9m36s
csi-rbdplugin-79k4l                                   3/3     Running     0          9m36s
csi-rbdplugin-b54fp                                   3/3     Running     0          9m36s
csi-rbdplugin-lxbl7                                   3/3     Running     0          9m36s
csi-rbdplugin-provisioner-57fc697f96-pjjvz            6/6     Running     0          9m36s
csi-rbdplugin-provisioner-57fc697f96-rgk8t            6/6     Running     0          9m36s
csi-rbdplugin-qfhk2                                   3/3     Running     0          9m36s
csi-rbdplugin-zsp64                                   3/3     Running     0          9m36s
rook-ceph-crashcollector-rc-s1-k8s-7845bbd484-w4mwt   1/1     Running     0          3m56s
rook-ceph-crashcollector-rc-s2-k8s-ff7fb9bbf-7stvz    1/1     Running     0          4m12s
rook-ceph-crashcollector-rc-s3-k8s-f4894649d-2pxhv    1/1     Running     0          4m25s
rook-ceph-mgr-a-5649fc8fcb-mdh4n                      1/1     Running     0          4m34s
rook-ceph-mon-a-6fc54d58c-25k48                       1/1     Running     0          8m2s
rook-ceph-mon-b-69b47d95b-b5lmk                       1/1     Running     0          6m6s
rook-ceph-mon-c-58df69d7d9-p8wpv                      1/1     Running     0          5m55s
rook-ceph-operator-58db6d984f-8hzh4                   1/1     Running     0          12m
rook-ceph-osd-0-d76d6f56-7v5dk                        1/1     Running     0          72s
rook-ceph-osd-1-6fcfdf57b9-rgkr5                      1/1     Running     0          73s
rook-ceph-osd-2-5d9c8b5fc8-2glmg                      1/1     Running     0          72s
rook-ceph-osd-prepare-rc-s1-k8s-m4trj                 0/1     Completed   0          92s
rook-ceph-osd-prepare-rc-s2-k8s-7scnb                 0/1     Completed   0          89s
rook-ceph-osd-prepare-rc-s3-k8s-tdxlx                 0/1     Completed   0          85s
rook-ceph-osd-prepare-rc-w1-k8s-mknzb                 0/1     Completed   0          82s
rook-ceph-osd-prepare-rc-w2-k8s-fdhmt                 0/1     Completed   0          79s
rook-ceph-osd-prepare-rc-w3-k8s-b9qtf                 0/1     Completed   0          76s
```
