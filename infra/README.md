# 🔒 On-Premise (Secure Zone) Infrastructure

이 디렉토리는 PayGuard 프로젝트의 핵심인 **금융/결제 민감 데이터 보관 및 보안 관제**를 담당하는 로컬 OpenStack 내부망 인프라 설정(IaC)을 포함하고 있습니다.

## ✨ 주요 보안 아키텍처
* **망분리 적용:** 퍼블릭 클라우드(kt cloud)와 분리되어 인터넷에서 직접 접근이 불가능한 격리 네트워크(`webserver` 대역)에 구성되었습니다.
* **TDE (Transparent Data Encryption):** MySQL 8.0 컨테이너의 물리적 볼륨에 `keyring_file` 플러그인을 강제 적용하여, 디스크(Data-at-Rest) 유출 시에도 완벽한 데이터 기밀성을 보장합니다.
* **ELK Audit Pipeline:** 5044 포트로 개방된 Logstash를 통해 DB 감사(Audit) 로그 및 애플리케이션 트랜잭션 로그를 실시간으로 수집하고 분석합니다.

## 🚀 실행 가이드 (How to run)

**1. 환경 변수 세팅**
보안 정책상 데이터베이스 비밀번호는 코드 저장소에 포함되지 않습니다. 템플릿을 복사하여 환경변수를 직접 주입해 주세요.
```bash
cd onpremise
cp .env.example .env
vi .env  # 내부의 DB_ROOT_PASSWORD, DB_USER_PASSWORD 값을 실제 사용할 비밀번호로 수정
