# demo-prom-darksite 
offline에서 promql을 조회하고 테스트하기 위해 만들었습니다. </br>

## 최소 조건 
CPU 2 cores
Mem 2048 Mi 이상 

## 사용법
```bash
$ vagrant up
Bringing machine 'demo-prom-darksite' up with 'virtualbox' provider...
==> demo-prom-darksite: Checking if box 'sysnet4admin/Ubuntu-k8s' version '0.7.1' is up to date...
==> demo-prom-darksite: Machine already provisioned. Run `vagrant provision` or use the `--provision`
==> demo-prom-darksite: flag to force provisioning. Provisioners marked to run always will still run.

    <snipped>

    demo-prom-darksite: For more information on running Prometheus, visit:
    demo-prom-darksite: https://prometheus.io/
    demo-prom-darksite: service/prometheus-server-np exposed
    demo-prom-darksite: service/prometheus-server-np patched
```
진행이 모두 완료된 이후에 
192.168.1.231:30000 으로 접속하면 프로메테우스 그래프 대시보드가 나옴 

## 주의할 점 
dockershim을 이용하기 때문에 쿠버네티스 버전 1.24로 넘어가야 할 경우에는 
docker-cri 또는 다른 런타임으로 변경이 필요함 
