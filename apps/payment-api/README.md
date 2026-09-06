# ☕ Payment API (결제 코어 애플리케이션)
Spring Boot 기반의 결제 시뮬레이션 애플리케이션입니다.
- **주요 기능**: 결제 트랜잭션 발생 및 DB 저장, Audit 로그 생성
- **로깅 정책**: 결제 감사 로그는 파일(`/var/log/payguard/audit.log`)로 남기며, K8s 환경에서 Filebeat Sidecar 컨테이너와 `emptyDir` 볼륨으로 공유되어 폐쇄망(ELK)으로 전송됩니다.
