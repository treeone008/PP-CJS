# PayGuard Infrastructure as Code (Ansible)

이 디렉토리는 PayGuard 프로젝트의 인프라(Kubernetes 및 네트워크 보안망)를 자동으로 구축하고 관리하기 위한 Ansible Playbook을 포함하고 있습니다. 모든 인프라 구성은 코드로 관리(IaC)되며 멱등성을 보장합니다.

## 📂 Playbook 리스트 및 역할

### 1. Kubernetes 클러스터 구축
* **`k8s-setup.yml`**: K8s 구동을 위한 기초 OS 튜닝(Swap 해제, 커널 파라미터), 컨테이너 런타임(`containerd`), `kubeadm` 등 필수 패키지를 모든 노드에 설치합니다. (Depsolve 충돌 및 CRI 버그 트러블슈팅 반영)
* **`k8s-master-init.yml`**: 마스터 노드의 Control Plane을 초기화하고 Calico CNI를 배포합니다. 워커 노드 합류를 위한 Join 토큰을 베스천 서버로 자동 추출합니다.
* **`k8s-worker-join.yml`**: 베스천 서버에 저장된 Join 토큰을 사용하여 워커 노드를 K8s 클러스터에 자동 편입시킵니다.

### 2. 라우팅 및 인그레스(Ingress)
* **`k8s-ingress.yml`**: Helm을 사용하여 Nginx Ingress Controller를 마스터 노드에 배포하고, 외부 트래픽을 받기 위한 NodePort(30080)를 개방합니다.
* **`k8s-test-app.yml`**: Ingress ➔ Service ➔ Pod로 이어지는 네트워크 라우팅이 정상적으로 동작하는지 검증하기 위한 테스트용 Nginx 웹 서버를 배포합니다.

### 3. 하이브리드 클라우드 보안망 (VPN)
* **`wg-bastion-setup.yml`**: kt cloud의 퍼블릭 K8s 망과 OpenStack 온프레미스 망(DB/ELK)을 안전하게 연결하기 위해 베스천 서버에 **WireGuard VPN**을 설치하고 암호화 키 페어를 생성합니다. 

## 🚀 실행 방법 (Usage)

플레이북은 `ansible/` 디렉토리 최상위에서 `inventory.ini`를 참조하여 실행합니다.

```bash
# 예시: K8s 기초 환경 구성 실행
ansible-playbook -i inventory.ini playbooks/k8s-setup.yml


---

## 📌 Appendix: WireGuard VPN 설정 템플릿

> **⚠️ Security Warning**
> 아래는 인프라 구조 파악을 위한 설정 파일(`wg0.conf`) 템플릿입니다. 

### 1. kt cloud Bastion 노드 (`/etc/wireguard/wg0.conf`)
* **역할:** 외부 클라우드 통신 관문 (VPN 가상 IP: 10.99.0.1)

```ini
[Interface]
Address = 10.99.0.1/24
ListenPort = 51820
PrivateKey = <BASTION_PRIVATE_KEY>

[Peer]
# On-Premise 서버의 Public Key
PublicKey = <ON_PREMISE_PUBLIC_KEY>
# 허용할 On-Premise 내부망 대역 (VPN IP 및 DB/ELK 대역)
AllowedIPs = 10.99.0.2/32, 192.168.1.0/24

### 2. On-Premise DB/ELK 노드 (`/etc/wireguard/wg0.conf`)
역할: 로컬 내부망 관문 (VPN 가상 IP: 10.99.0.2)

```ini
[Interface]
Address = 10.99.0.2/24
ListenPort = 51820
PrivateKey = <ON_PREMISE_PRIVATE_KEY>

[Peer]
# Bastion 서버의 Public Key
PublicKey = <BASTION_PUBLIC_KEY>
# 허용할 kt cloud 내부망 대역 (VPN IP, 노드 대역, K8s Pod 대역)
AllowedIPs = 10.99.0.1/32, 172.27.0.0/24, 192.168.0.0/16
# kt cloud 베스천 서버의 공인 IP 및 포트포워딩 포트
Endpoint = <BASTION_PUBLIC_IP>:51820
PersistentKeepalive = 25
