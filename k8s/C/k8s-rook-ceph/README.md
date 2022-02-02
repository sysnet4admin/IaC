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
NAME                                                  READY   STATUS      RESTARTS   AGE
csi-cephfsplugin-6ffvf                                3/3     Running     0          14m
csi-cephfsplugin-jvsng                                3/3     Running     0          14m
csi-cephfsplugin-provisioner-b4f7d7bd4-5gszs          6/6     Running     0          14m
csi-cephfsplugin-provisioner-b4f7d7bd4-6sb2s          6/6     Running     0          14m
csi-cephfsplugin-sw5lp                                3/3     Running     0          14m
csi-cephfsplugin-zkfs6                                3/3     Running     0          14m
csi-cephfsplugin-zxm7q                                3/3     Running     0          14m
csi-cephfsplugin-zxzgq                                3/3     Running     0          14m
csi-rbdplugin-fx4vr                                   3/3     Running     0          14m
csi-rbdplugin-nlt27                                   3/3     Running     0          14m
csi-rbdplugin-p6l6x                                   3/3     Running     0          14m
csi-rbdplugin-provisioner-57fc697f96-jbc5m            6/6     Running     0          14m
csi-rbdplugin-provisioner-57fc697f96-w96m8            6/6     Running     0          14m
csi-rbdplugin-s9hhp                                   3/3     Running     0          14m
csi-rbdplugin-wcvgh                                   3/3     Running     0          14m
csi-rbdplugin-x2qp4                                   3/3     Running     0          14m
rook-ceph-crashcollector-rc-s1-k8s-7845bbd484-s2ljc   1/1     Running     0          10m
rook-ceph-crashcollector-rc-s2-k8s-ff7fb9bbf-hrph2    1/1     Running     0          8m30s
rook-ceph-crashcollector-rc-s3-k8s-f4894649d-4tlxf    1/1     Running     0          8m55s
rook-ceph-crashcollector-rc-w1-k8s-746f49dcc8-f5q5c   1/1     Running     0          10m
rook-ceph-crashcollector-rc-w2-k8s-69566cd557-wbllg   1/1     Running     0          10m
rook-ceph-mgr-a-556f955489-2nqh7                      1/1     Running     0          10m
rook-ceph-mon-a-774c94b8cd-26sbg                      1/1     Running     0          14m
rook-ceph-mon-b-6dc865c469-lns6g                      1/1     Running     0          13m
rook-ceph-mon-c-5d9689cf5f-g8mz4                      1/1     Running     0          11m
rook-ceph-operator-58db6d984f-f97hr                   1/1     Running     0          16m
rook-ceph-osd-0-6c45487cd7-l892j                      1/1     Running     0          9m18s
rook-ceph-osd-1-dc8967f7-pjq5j                        1/1     Running     0          8m55s
rook-ceph-osd-2-56897b557-vwwqm                       1/1     Running     0          8m30s
rook-ceph-osd-prepare-rc-s1-k8s-qdwws                 0/1     Completed   0          5m29s
rook-ceph-osd-prepare-rc-s2-k8s-p9d9t                 0/1     Completed   0          5m26s
rook-ceph-osd-prepare-rc-s3-k8s-wpnjx                 0/1     Completed   0          5m23s
rook-ceph-osd-prepare-rc-w1-k8s-cllm8                 0/1     Completed   0          5m20s
rook-ceph-osd-prepare-rc-w2-k8s-6fpb9                 0/1     Completed   0          5m17s
rook-ceph-osd-prepare-rc-w3-k8s-jvhpk                 0/1     Completed   0          5m14s

