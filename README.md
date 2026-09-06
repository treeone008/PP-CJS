# 🛡️ PayGuard: Hybrid DevSecOps Platform

**금융권 망분리 규제 준수를 위한 하이브리드 클라우드(kt cloud & OpenStack) 기반 DevSecOps 인프라 구축 프로젝트**

## 📌 Project Overview (프로젝트 개요)
PayGuard는 금융/결제 도메인의 보안 컴플라이언스(전자금융감독규정 망분리 기준 등)를 충족하면서도 모던 데브옵스의 민첩성을 극대화한 하이브리드 클라우드 DevSecOps 플랫폼입니다. 
트래픽 확장이 필요한 애플리케이션 서비스는 **퍼블릭 클라우드(kt cloud)**에 배포하고, 민감 정보가 포함된 데이터베이스와 감사(Audit) 로그는 **온프레미스 사설망(Local OpenStack)**으로 철저히 격리 보관합니다.

## ✨ Key Features (주요 구현 성과)
1. **하이브리드 망분리 아키텍처**: kt cloud(Public)와 OpenStack(Private) 간 WireGuard VPN 터널링을 통한 안전한 하이브리드 통신 구축
2. **DevSecOps 파이프라인 (보안 내재화)**: Jenkins + Trivy를 연동하여 컨테이너 이미지 취약점(CRITICAL) 발견 시 자동 배포 차단 (Shift-Left Security)
3. **완전한 관측성(Observability) 확보**: 
   - 앱 메트릭: K8s Metrics Server, Prometheus & Grafana 연동
   - 보안 감사 로그: Filebeat(Sidecar) -> Logstash -> Elasticsearch -> Kibana(폐쇄망) 로그 파이프라인 구축
4. **트래픽 자동 확장 (HPA)**: 부하 테스트(Apache Bench) 기반 임계치 도달 시 Pod 자동 스케일아웃(Scale-out) 검증 완료

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
│    ├── Payment API Pods (App + Filebeat Sidecar)            │
│    ├── CI/CD: Jenkins, Trivy (Security Scan)                │
│    └── Observability: Prometheus, Grafana                   │
└──────────────────────────────┬──────────────────────────────┘
                               │
               [ WireGuard VPN Tunnel / Private Network ]
                               │
┌──────────────────────────────▼──────────────────────────────┐
│ Local On-Premise (OpenStack) - Secure Zone (Core)           │
│  [ IP: 192.168.1.129 ]                                      │
│  ├── Database (MySQL - Sensitive Payment Data)              │
│  └── Enterprise ELK Stack (Security & Audit Logs Analysis)  │
└─────────────────────────────────────────────────────────────┘

📂 Repository Structure (디렉토리 구조)
PP-CJS/
├── ansible/          # ⚙️ Configuration Management (Jenkins, K8s, VPN 자동 구성)
├── apps/             # ☕ Spring Boot 결제 API 애플리케이션 소스 코드
├── infra/            # 🏗️ 온프레미스 Secure Zone 인프라 (DB, ELK docker-compose)
├── k8s/              # ☸️ Kubernetes 배포 매니페스트 (App, HPA, Monitoring)
├── terraform/        # ☁️ kt cloud 인프라 프로비저닝 (IaC)
├── Dockerfile        # 🐳 결제 API 컨테이너 이미지 빌드 파일
└── Jenkinsfile       # 🚀 CI/CD 및 DevSecOps 파이프라인 스크립트
