# 💳 PayGuard (PP-CJS) — 금융권 하이브리드 클라우드 & DevSecOps 인프라 구축

> **전자금융감독규정(망분리)을 준수하는 이기종 하이브리드 클라우드(kt cloud + OpenStack) 아키텍처 및 무중단 DevSecOps/관측성 파이프라인 구축 프로젝트**

---

## 🎯 1. 프로젝트 배경 및 핵심 목표 (Project Overview)

* **배경:** 금융·결제 시스템은 법적 규제(물리적·논리적 망분리)로 인해 민감 데이터를 온프레미스 내부망에 격리해야 하지만, 대규모 결제 트래픽 폭주에 대응하기 위한 퍼블릭 클라우드의 유연한 확장성(Auto-scaling) 또한 필수적입니다.
* **핵심 엔지니어링 목표:**
  1. **하이브리드 망분리 및 DB 보안:** 퍼블릭 클라우드(`kt cloud`)의 K8s 클러스터와 온프레미스(`OpenStack`) 보안 존을 **WireGuard VPN** 암호화 터널로 연결하고, MySQL 8.0에 **TDE(`keyring_file`) 물리 암호화** 적용.
  2. **Shift-Left DevSecOps:** **Multi-stage Docker 빌드**로 환경 종속성을 제거하고, **Jenkins + Trivy**를 통해 `CRITICAL` 취약점 발견 시 배포를 즉시 차단하는 자동화 파이프라인 구축.
  3. **관측성(Observability) 이원화:** 운영 메트릭(Metrics Server / Prometheus)과 민감 결제 감사 로그(**Filebeat Sidecar ➔ VPN ➔ 온프레미스 ELK Stack**)의 수집 경로를 분리하여 보안 규제 준수 및 리소스 최적화 달성.
  4. **대규모 트래픽 방어 검증:** 50,000건 동시 결제 부하 발생 시 **K8s HPA**가 CPU 폭증(482%)을 감지하여 파드를 최대치(5개)로 즉각 Scale-out 방어.

---

## 🏛️ 2. 시스템 아키텍처 (System Architecture)

```text
[ Internet / Users ]
        │
        ▼ (HTTP/HTTPS - Port Forwarding & Security Group)
┌─────────────────────────────────────────────────────────────┐
│ kt cloud (KOR-Seoul M / 172.27.0.0/24) - Public & App Zone  │
│                                                             │
│  [ DMZ / Control Node ]                                     │
│    └── Bastion Host (172.27.0.95): NAT GW, Ansible, Jenkins │
│                                                             │
│  [ Private Subnet - Kubernetes Cluster (Calico CNI) ]       │
│    ├── Master Node (172.27.0.7) / Worker Node (172.27.0.176)│
│    ├── Ingress Nginx (NodePort 30080 -> /api/v1/payment)    │
│    ├── Payment API Pods (Spring Boot + Filebeat Sidecar)    │
│    ├── DevSecOps & GitOps: Jenkins, Trivy, GHCR, ArgoCD     │
│    └── Cluster Metrics: Metrics Server (HPA), Prometheus    │
└──────────────────────────────┬──────────────────────────────┘
                               │
         [ WireGuard VPN Tunnel (10.99.0.x / UDP 51820) ]
                               │
┌──────────────────────────────▼────────────────────────────────┐
│ Local On-Premise (OpenStack / 192.168.1.129) - Secure Zone    │
│                                                               │
│  ├── Core Database: MySQL 8.0 (TDE keyring_file 암호화 적용)   │
│  └── Enterprise ELK Stack (Logstash ➔ Elasticsearch ➔ Kibana │
│      : payguard-logs-* 결제/보안 감사 로그 실시간 적재·관제)     │
└───────────────────────────────────────────────────────────────┘
```

---

## 🛠️ 3. 기술 스택 및 저장소 구조 (Tech Stack & Structure)

* **Cloud & IaC:** kt cloud, OpenStack, Terraform, Ansible
* **Container & Orchestration:** Kubernetes (`v1.28`), Docker, containerd, Calico CNI, Nginx Ingress
* **CI/CD & DevSecOps:** Jenkins, Trivy, GitHub Container Registry (`ghcr.io`), ArgoCD
* **Network & Security:** WireGuard VPN, Linux `iptables` (SNAT/Masquerade), MySQL TDE (`keyring_file`), K8s Secret/ConfigMap
* **Observability & App:** ELK Stack (`8.12.1`), Filebeat (Sidecar), Metrics Server, Spring Boot (`Java 21`)

```text
PP-CJS/
├── ansible/          # ⚙️ K8s 클러스터링, 컨테이너 런타임, Ingress, VPN 자동 구성 Playbook
├── apps/             # ☕ Spring Boot (Java 21) 결제 API 애플리케이션 소스 코드
├── infra/            # 🏗️ 온프레미스 Secure Zone 인프라 (MySQL TDE, ELK docker-compose)
├── k8s/              # ☸️ Kubernetes 배포 매니페스트 (Deployment, Sidecar, HPA, Ingress)
├── terraform/        # ☁️ kt cloud 인프라 프로비저닝 코드 (IaC)
├── Dockerfile        # 🐳 Multi-stage 빌드 기반 결제 API 컨테이너 이미지 파일
└── Jenkinsfile       # 🚀 빌드 ➔ Trivy 취약점 스캔 ➔ GHCR 푸시 ➔ K8s 배포 파이프라인
```

---

## ⚖️ 4. 아키텍처 의사결정 기록 (Architecture Decision Records)

### ADR-01. 하이브리드 클라우드 VPN 솔루션 채택 (WireGuard vs OpenVPN vs IPsec)
* **배경:** 퍼블릭 인터넷을 경유하는 kt cloud(App)와 온프레미스(DB/ELK) 구간의 패킷 탈취 방지를 위해 암호화 터널링 구축이 필수적임.
* **대안 비교:**

| 비교 항목 | WireGuard (채택 ✅) | OpenVPN | IPsec (StrongSwan) |
| :--- | :--- | :--- | :--- |
| **속도 및 성능** | **가장 빠름** (커널 스페이스 동작, 지연 최소화) | 느림 (유저 스페이스 동작) | 빠름 (커널 스페이스 동작) |
| **코드 복잡도** | **약 4,000줄** (가볍고 보안 감사 용이) | 100,000줄 이상 (무거움) | 400,000줄 이상 (매우 복잡) |
| **암호화 기술** | **최신 표준 단일화** (ChaCha20-Poly1305) | 구/신형 혼합 (협상 지연) | 복잡한 스위트 (IKE, ESP) |
| **IaC 자동화** | **최상** (직관적인 설정 파일) | 하 (인증서 PKI 인프라 필요) | 최하 (NAT 통과 설정 복잡) |

* **결정 및 근거:** 결제 트랜잭션 처리 특성상 K8s 파드와 온프레미스 DB 간 **지연 시간(Latency) 최소화(평균 RTT ~13ms)**가 핵심이며, Ansible 기반 IaC 자동화에 가장 유리한 커널 기반 **WireGuard**를 최종 채택함.

### ADR-02. 감사 로그 수집(Observability)을 위한 Filebeat Sidecar 패턴 채택
* **배경:** K8s 클러스터 내 결제 API의 감사(Audit) 로그를 온프레미스 ELK 스택으로 유실 없이 전송해야 함.
* **결정 및 근거:** 노드 단위 `DaemonSet` 대신 애플리케이션 파드 내부에 Filebeat 컨테이너를 함께 배치하고 `emptyDir` 볼륨을 공유하는 **Sidecar 패턴**을 채택함. 타 시스템 로그와 민감 결제 로그가 섞이는 것을 원천 분리하고, HPA를 통해 파드가 Scale-out될 때 로그 수집기도 동일한 생명주기로 확장되어 로깅 병목을 방지함.

### ADR-03. CI/CD 파이프라인의 Multi-stage Docker 빌드 도입
* **배경:** 초기 Jenkins 호스트에서 Gradle/JDK 플러그인으로 직접 빌드 시 호스트 OS 환경 종속성 및 버전 충돌 우려가 발생함.
* **결정 및 근거:** **Multi-stage Dockerfile**을 도입하여 1단계(Builder) 컨테이너에서 소스 빌드를 수행하고, 최종 이미지에는 순수 런타임(`.jar`)만 패키징함. 이를 통해 빌드 환경의 100% 멱등성(Idempotence)을 보장하고 컨테이너 이미지 크기를 경량화함.

### ADR-04. DevSecOps Shift-Left 보안 스캐닝 및 K8s Secret 분리
* **배경:** 컨테이너 이미지 취약점(CVE)이 운영 클러스터에 배포된 후 발견되면 조치 비용이 급증하며, DB 접속 정보를 코드에 하드코딩할 경우 심각한 보안 위협이 됨.
* **결정 및 근거:** Jenkins 빌드 직후 **Trivy** 스캐너를 연동해 `CRITICAL` 취약점 탐지 시 파이프라인을 즉시 중단(`exit 1`)하도록 구현하고, 온프레미스 DB 접속 정보는 `K8s Secret` 및 `ConfigMap`으로 분리 주입하여 Zero-Trust 원칙을 준수함.

### ADR-05. kt cloud 환경 프로비저닝 도구(IaC) 역할 분리
* **배경:** kt cloud G1/G2 환경에서 Terraform `cloudstack` 프로바이더 사용 시 벤더사 커스텀 API 구조로 인해 VPC Offering 등 필수 파라미터 통신 불가 현상 확인.
* **결정 및 근거:** 무리한 우회 스크립트로 유지보수성을 해치는 대신, 초기 VM 프로비저닝은 콘솔로 신속히 처리하고 **OS 패키지, 컨테이너 런타임, K8s 클러스터링, 방화벽/라우팅 등 내부 구성(Configuration)은 Bastion 서버의 Ansible Playbook으로 100% 코드화**하여 통제력을 유지함.

---

## 🔥 5. 주요 트러블슈팅 (Troubleshooting Log)

### 1) 크립토재킹(xmrig) 침해 사고 초동 대응 및 FinOps 사설망 전면 재설계
* **문제:** 초기 CI/CD 테스트 중 외부 웹 포트(8080) 임시 개방 틈을 타 채굴 악성코드(`xmrig`)가 침투하여 CPU 점유율 100% 마비 발생.
* **해결:** 강제 종료 시 데몬에 의해 즉시 재실행되는 것을 막기 위해 `pkill -STOP xmrig`로 프로세스를 일시 정지시킨 뒤 실행 경로에 불변 속성(`chattr +i`)을 부여해 무력화함. 이후 방화벽을 전면 초기화하고, K8s 마스터/워커 노드의 공인 IP를 제거해 순수 사설망(`172.27.0.x`)으로 격리한 뒤 베스천 포트포워딩(`22001 ➔ 22`)을 통한 단일 관문 아키텍처로 재구축함.

### 2) K8s 파드 ➔ 온프레미스 DB 하이브리드 라우팅 단절 및 Calico SNAT 누락 해결
* **문제:** 워커 노드 호스트에서는 온프레미스 DB(`192.168.1.129:3306`)로 통신이 되나, K8s 내부 Spring Boot 파드에서는 `Communications link failure` 타임아웃이 발생하며 `CrashLoopBackOff`에 빠짐.
* **원인:** 파드 가상 IP(`10.x.x.x`) 패킷이 워커 노드를 빠져나갈 때 Calico CNI 기본 정책에 가로막혀 호스트 물리 IP로 출발지 주소 변환(SNAT)이 이루어지지 않아 응답 패킷이 유실됨.
* **해결:** 베스천 서버에 커널 포워딩(`net.ipv4.ip_forward=1`)과 `FORWARD` 허용 룰을 적용하고, 워커 노드에 정적 라우트(`ip route add 192.168.1.0/24 via 172.27.0.95`) 및 `iptables -t nat -I POSTROUTING 1 -d 192.168.1.0/24 -j MASQUERADE` 규칙을 최상단(1순위)으로 삽입해 파드-DB 간 암호화 터널 통신을 100% 복구함.

### 3) 자체 구축 K8s 환경의 Metrics Server 포트 충돌 및 HPA `<unknown>` 장애 해결
* **문제:** HPA 구동을 위해 배포한 Metrics Server가 `ServiceUnavailable`을 반환하고, `hostNetwork: true` 적용 시 `bind: address already in use` 에러로 `CrashLoopBackOff` 발생. 또한 복구 후에도 HPA의 `TARGETS`가 `<unknown>/30%`로 표시되며 스케일아웃이 동작하지 않음.
* **원인:** ① 호스트 네트워크 사용 시 기본 포트(`10250`)가 호스트 `kubelet` 포트와 충돌함. ② HPA는 파드 내 **모든 컨테이너의 CPU Request 합산값**을 분모로 사용률을 계산하는데, 메인 앱(`100m`)에만 Request를 설정하고 사이드카(`filebeat`)에 누락하여 퍼센트 산출에 실패함.
* **해결:** Metrics Server 구동 포트를 `4443`으로 우회 및 `--kubelet-insecure-tls` 옵션을 주입해 지표 수집을 정상화하고, `filebeat` 사이드카 컨테이너에 CPU Request(`50m`)를 명시하여 HPA 자동 확장을 성공시킴.

### 4) Rocky Linux 컨테이너 런타임 충돌 및 K8s Swap 메모리 스케줄링 장애 해결
* **문제:** OS 내장 `podman`(`runc`)과 `containerd.io` 간 패키지 충돌이 발생하고, 클러스터 조인 후 워커 노드가 `NotReady` 상태에 빠지며 파드가 `Pending`에 머무름.
* **해결:** Ansible `dnf` 모듈에 `allowerasing: yes`와 `config.toml`의 `disabled_plugins = ["cri"]` 주석 처리 태스크를 코드화하고, `journalctl` 로그 분석을 통해 원인으로 확인된 Swap 메모리를 영구 비활성화(`swapoff -a`)하여 클러스터를 안정화함.

---

## 📊 6. 종합 검증 결과 (Validation Summary)

1. **DevSecOps 차단 검증:** 취약한 베이스 이미지(`openjdk:8-jdk-alpine`) 푸시 시 Jenkins 내 Trivy 스캔 단계에서 `CRITICAL` 취약점을 탐지하여 배포 전 파이프라인 자동 중단(`Failed`) 확인 후 정상 이미지 롤백 완료.
2. **망분리 보안 검증:** 외부 공인망에서 온프레미스 DB(`3306`) 직접 접근은 방화벽에 의해 차단되며, 오직 K8s 클러스터 내부 파드에서 WireGuard VPN 라우팅 경로를 통해서만 접근 가능함을 검증.
3. **50,000건 부하 테스트 및 HPA 방어 검증:** Apache Bench(`ab -n 50000 -c 100`) 부하 주입 시 CPU 사용률 급증(**482%**)을 감지하여 파드가 **1개에서 최대치인 5개로 즉각 Scale-out**되며 트래픽을 유실 없이 방어하고, 모든 결제 감사 로그가 Kibana(`payguard-logs-*`)에 실시간 적재됨을 확인.
