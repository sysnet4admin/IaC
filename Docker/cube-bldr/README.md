도커 빌드하고, 쿠버 테스트하고 하는 환경을 통합하기 위해서 베이그런트 스크립트를 만들었습니다. 
- docker 
- minikube
- custom-git 

## 사용법
```bash
vagrant up
```
끝나면, 아래의 명령을 실행하고 나오는 결과를 
```bash 
cat ~/.ssh/id_rsa.pub 
```
깃허브 SSH Key로 등록하면 됩니다 

custom-git은 자유롭게 개인 수정해서 쓰면 됩니다. :) 
(현재는github에 제 계정으로 되어 있습니다.)

접속 경로는 `127.0.0.1:60091` 입니다!
