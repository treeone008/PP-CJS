# 🛡️ PayGuard: Hybrid DevSecOps Platform

> **금융권 망분리 규제 준수를 위한 하이브리드 클라우드(kt cloud & OpenStack) 기반 DevSecOps 인프라 구축 프로젝트**

---

## 📌 Project Overview (프로젝트 개요)

PayGuard는 금융/결제 도메인의 보안 컴플라이언스(전자금융감독규정 망분리 기준 등)를 충족하면서도 모던 데브옵스의 민첩성을 극대화한 **하이브리드 클라우드 DevSecOps 플랫폼**입니다.

트래픽 확장이 필요한 애플리케이션 서비스는 **퍼블릭 클라우드(kt cloud)**에 배포하고, 민감 정보가 포함된 데이터베이스와 감사(Audit) 로그는 **온프레미스 사설망(Local OpenStack)**으로 철저히 격리 보관합니다.

---

## 🏛️ High-Level Architecture (아키텍처 구성도)

```text
[ Internet / Users ]
        │
        ▼ (HTTPS)
┌─────────────────────────────────────────────────────────────┐
│ kt cloud (CloudStack G1/G2) - Public & App Zone             │
│                                                             │
│  [ DMZ ]                                                    │
│    └── Bastion Host / Ingress Nginx                         │
│                                                             │
│  [ Private Subnet - Kubernetes Cluster ]                    │
│    ├── Payment API Pods (Docker Containers)                 │
│    ├── CI/CD: Jenkins, ArgoCD (GitOps)                      │
│    └── Observability: Prometheus, Grafana, Loki             │
└──────────────────────────────┬──────────────────────────────┘
                               │
               [ Encrypted VPN Tunnel / Private Network ]
                               │
┌──────────────────────────────▼──────────────────────────────┐
│ Local On-Premise (OpenStack) - Secure Zone (Core)           │
│                                                             │
│  ├── Database (Sensitive Payment Data)                      │
│  └── Enterprise ELK Stack (Security & Audit Logs Analysis)  │
└─────────────────────────────────────────────────────────────┘


📂 Repository Structure (저장소 구조 - 예정)

payguard-platform/
├── .gitignore
├── README.md
├── terraform/                # kt cloud 인프라 프로비저닝 (IaC)
│   ├── modules/
│   │   ├── network/          # VPC, Subnet, ACL/Security Group
│   │   └── compute/          # Bastion, K8s Master/Worker VM
│   ├── environments/
│   │   └── prod/             # main.tf, variables.tf, outputs.tf
│   └── README.md
├── ansible/                  # 서버 환경 설정 자동화
│   ├── inventories/          # 호스트 IP 정의 (hosts.ini)
│   ├── playbooks/            # k8s-init.yml, docker-install.yml, vpn-setup.yml
│   ├── roles/                # 공통 설정 모듈화
│   └── ansible.cfg
├── k8s/                      # 쿠버네티스 매니페스트 및 Helm
│   ├── apps/                 # PayGuard 결제 앱 (deployment, service, ingress)
│   ├── cicd/                 # ArgoCD, Jenkins agent 매니페스트
│   └── monitoring/           # Prometheus, Grafana, Loki Helm values
├── pipelines/                # Jenkins 파이프라인 스크립트
│   └── Jenkinsfile           # Trivy 보안 스캔 + Build + Push + GitOps Sync
├── apps/                     # PayGuard 결제 API 소스 코드
│   └── payment-api/          # Dummy Web/WAS 소스 및 Dockerfile
├── onpremise/                # 로컬 OpenStack (DB 및 ELK Stack 구성)
│   ├── db/                   # MySQL/PostgreSQL 초기화 스크립트
│   └── elk/                  # Logstash 파이프라인, Elasticsearch 설정, docker-compose
└── docs/                     # 트러블슈팅, 아키텍처 다이어그램 및 ADR(의사결정기록)
