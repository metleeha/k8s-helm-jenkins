# Kubernetes Cluster에 Jenkins 직접 설치하기

> Kubernetes Cluster에 Helm chart로 Jenkins  설치해보기 

이 튜토리얼은 쿠버네티스 클러스터 상에 Jenkins를 설치하는 방법을 설명합니다. 쿠버네티스 클러스터는 로컬에서 설치해 사용하는 minikube, Public Cloud 플랫폼에서 제공하는 AWS EKS, GCP GKE, Azure AKS, IBM IKS 등 어떤 서비스를 사용해도 괜찮습니다. 

## Jenkins 란 ? 

Jenkins는 소프트웨어 개발 시 지속적으로 통합서비스를 제공하는 툴입니다. CI(Continuous Integration) 툴이라고 표현합니다. 여러명의 개발자들이 하나의 프로그램을 동시에 개발할 때 버전 충돌을 방지하기 위해 만들어졌습니다. 각자 작업한 내용을 공유 영역이 있는 저장소에 업로드함으로써 지속적인 통합이 가능하도록 해줍니다.

원래 허드슨 프로젝트로 개발되었고, 2004년 여름 썬 마이크로시스템즈에서 시작되었습니다. 2005년 2월에 java.net에 처음 출시되었습니다.

젠킨스 같은 CI 툴이 등장하기 전에는 일정 시간마다 빌드를 실행하는 방법이 일반적이었습니다. 주로 개발자들이 낮에 업무를 끝내고 심야에 빌드를 진행하는 방식으로 nightly-build라고 불렸습니다. 젠킨스는 여기서 한발자국 더 나아가 Git 같은 버전관리 시스템과 연동해 소스 커밋을 감지하고, 자동화 테스트를 거쳐 빌드를 작동시킬 수 있는 기능을 제공합니다.

젠킨스는 다음과 같은 이점들을 대표적으로 제공합니다.

- 결합 테스트 환경에 대한 배포 작업
- 정적 코드 분석에 의한 코딩 규약 준수여부 체크
- 자동화 테스트 수행
- 프로파일링 툴을 이용해 소스 변경시 성능 변화 감시
- 프로젝트 표준 컴파일 환경에서의 컴파일 오류 검출

젠킨스는 블로그 포스팅을 통해 꾸준히 업데이트된 기능과 문서 정리가 잘 되어있습니다. 자세한 이용 방법과 관련 정보는 [공식 홈페이지](https://www.jenkins.io/)를 참고해주세요.

이제 젠킨스를 Kubernetes cluster에 올려 사용하기 위해 설치 작업을 진행해보도록 하겠습니다.


## 선행 조건

- 커맨드 라인/터미널 접근
- 쿠버네티스 클러스터
- kubectl 명령 도구 구성
- Helm (ver.3)

## Steps

- Jenkins 배포를 위한 네임스페이스 생성
- Jenkins PersistentVolume/PersistentVolumeClaim 생성
- Helm(ver.3)으로 Jenkins 설치
- Jenkins 설치 확인 및 로그인
- 정리하기


### Jenkins 배포를 위한 네임스페이스 생성

Jenkins 설치를 진행할 쿠버네티스 네임스페이스 생성

```bash
kubectl create namespace jenkins-demo
```

결과창

```bash
namespace/jenkins-demo created
```

### Jenkins PersistentVolume/PersistentVolumeClaim 생성

PersistentVolume는 Jenkins Pod가 없어지고 새로 생성되더라도 관련 파일을 보존하는 역할을 합니다. 리눅스 편집기(nano, vim 등)를 이용해 yaml 파일을 작성하세요. 클라우드 서비스들의 경우 클라우드 편집기를 제공하는 경우도 있습니다. 

단, 이번에는 pvc를 지정해주지 않고 젠킨스를 설치했습니다. 미리 프라이빗 환경 혹은 로컬에서는 미리 pvc를 만들어두고 helm 속성값으로 지정해두면 지정된 pvc에 jenkins 데이터를 저장할 수 있습니다. 
쿠버네티스 서비스별로 프로비저닝을 제공하는 방법이 다르고 자세한 내용은 [공식문서](https://kubernetes.io/ko/docs/concepts/storage/storage-classes/)에서 확인하실 수 있습니다.


### Helm(ver.3)으로 Jenkins 설치
[Jenkins Helm Chart](https://github.com/helm/charts/tree/master/stable/jenkins)를 다운받아 설치합니다.

helm3 버전 체크 
```bash
helm version
# 출력 결과
version.BuildInfo{Version:"v3.2.1", GitCommit:"", GitTreeState:"clean", GoVersion:"go1.13.10"}
```
helm repo 추가 
```bash
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
```
차트 리스트 출력해서 확인 
```bash
helm search repo stable/jenkins
# 출력 결과
NAME          	CHART VERSION	APP VERSION	DESCRIPTION
stable/jenkins	2.0.1        	lts        	Open source continuous integration server. It s...
```
helm repo 업데이트 
```bash
helm repo update
```

#### Jenkins 설치 
helm 설치할 때 사용할 이름과 영구볼륨클레임, 서비스타입, 네임스페이스 등 속성값을 함께 지정해줍니다. 
기본 바탕 [values.yaml](https://github.com/helm/charts/blob/master/stable/jenkins/values.yaml) 파일을 기준으로 플러그인 설치 등 추가 설정 사항을 변경합니다. 

```bash
helm install demo-jenkins stable/jenkins \
--set persistence.existingClaim=false \
--set master.serviceType=NodePort \
--namespace jenkins-demo
```

### Jenkins 설치 확인 및 로그인
접속할 수 있는 url 정보를 shell 명령어로 출력합니다.

show_url.sh 파일에 실행 권한을 줍니다.  
```bash
chmod 755 show_url.sh
```
명령어를 수행할때 입력값으로 네임스페이스 명을 사용합니다.
url 접속정보, 계정, 패스워드를 출력해 줍니다.  
> 스크립트 파일에 jenkins 앱 이름, 서비스 이름, 네임스페이스 등 입력한 값에 따라 수정해주세요. 
```bash
./show_url.sh
```
콘솔 화면에 다음과 같이 출력 됩니다.   
pod가 생성되는데 수분의 시간이 걸립니다. 
pod가 생성 완료 되었는지 확인 한 후 아래 url정보를 복사하여 브라우저에서 실행 합니다.    

```bash
Jenkins url is http://169.56.75.43:31225/login
ID is admin
admin passwd is KGcmzLS7BV
```


## Source Code 
- [Git Repo](https://github.ibm.com/metleeha/k8s-helm-jenkins)


## Reference 
- Phoenixap, (June 16, 2020), https://phoenixnap.com/kb/how-to-install-jenkins-kubernetes
- Google Cloud, (June 16, 2020), https://cloud.google.com/solutions/jenkins-on-kubernetes-engine-tutorial?hl=ko
- Medium, (June 16, 2020), https://medium.com/appfleet/how-to-set-up-jenkins-on-kubernetes-70f8eac3dc7e